require "version_from_shard"

module Fzy
  extend self

  VersionFromShard.declare

  SCORE_MIN               = -Float32::INFINITY
  SCORE_MAX               = Float32::INFINITY
  SCORE_GAP_LEADING       = -0.005_f32
  SCORE_GAP_TRAILING      = -0.005_f32
  SCORE_GAP_INNER         =  -0.01_f32
  SCORE_MATCH_CONSECUTIVE =    1.0_f32
  SCORE_MATCH_SLASH       =    0.9_f32
  SCORE_MATCH_WORD        =    0.8_f32
  SCORE_MATCH_CAPITAL     =    0.7_f32
  SCORE_MATCH_DOT         =    0.6_f32

  # A search operation returns an array of Match objects, these objects stores the matching score and the
  # position of matched characters.
  class Match
    include Comparable(Match)

    # Array of size of needle string, containing the Position of each needle character into haystack string.
    getter positions
    # Result of the match.
    getter value
    # Match score.
    getter score

    # :nodoc:
    def initialize(@value : String, @score : Float32, @positions : Array(Int32))
    end

    # :nodoc:
    def initialize(needle : String, lower_needle : String, prepared_haystack : PreparedHaystack, index : Int32)
      haystack = prepared_haystack.haystack[index]
      n = needle.size
      m = haystack.size

      if n.zero? || m.zero? || m > 1024
        # Unreasonably large candidate: return no score
        # If it is a valid match it will still be returned, it will
        # just be ranked below any reasonably sized candidates
        @score = SCORE_MIN
        @positions = Array.new(n, -1)
      elsif n == m
        # Since this method can only be called with a haystack which
        # matches needle. If the lengths of the strings are equal the
        # strings themselves must also be equal (ignoring case).
        @score = SCORE_MAX
        @positions = Array.new(n) { |i| i }
      else
        d_table = Array.new(n, [] of Float32)
        m_table = Array.new(n, [] of Float32)
        compute_match(d_table, m_table, n, m, lower_needle, prepared_haystack.lower_haystack[index], prepared_haystack.bonus(index))

        @positions = positions(n, m, d_table, m_table)
        @score = m_table[n - 1][m - 1]
      end

      @value = haystack
    end

    # A match is greater than other if it has a greater score.
    def <=>(other)
      other.score <=> @score
    end

    private def compute_match(d_table, m_table, n, m, lower_needle, lower_haystack, match_bonus)
      # d_table[][] Stores the best score for this position ending with a match.
      # m_table[][] Stores the best possible score at this position.

      prev_score = SCORE_MIN
      n.times do |i|
        d_table[i] = Array.new(m, 0_f32)
        m_table[i] = Array.new(m, 0_f32)

        prev_score = SCORE_MIN
        gap_score = i == n - 1 ? SCORE_GAP_TRAILING : SCORE_GAP_INNER

        m.times do |j|
          if lower_needle[i] == lower_haystack[j]
            score = SCORE_MIN
            if i.zero?
              score = (j * SCORE_GAP_LEADING) + match_bonus[j]
            elsif j > 0 # i > 0 && j > 0
              score = Math.max(
                m_table[i - 1][j - 1] + match_bonus[j],
                # consecutive match, doesn't stack with match_bonus
                d_table[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE)
            end
            d_table[i][j] = score
            m_table[i][j] = prev_score = Math.max(score, prev_score + gap_score)
          else
            d_table[i][j] = SCORE_MIN
            m_table[i][j] = prev_score = prev_score + gap_score
          end
        end
      end
    end

    private def positions(n : Int32, m : Int32, d_table, m_table) : Array(Int32)
      positions = Array.new(n, -1)

      # backtrack to find the positions of optimal matching
      match_required = false

      (n - 1).downto(0) do |i|
        (m - 1).downto(0) do |j|
          # There may be multiple paths which result in
          # the optimal weight.
          #
          # For simplicity, we will pick the first one
          # we encounter, the latest in the candidate
          # string.
          if (d_table[i][j] != Fzy::SCORE_MIN) && (match_required || d_table[i][j] == m_table[i][j])
            # If this score was determined using
            # SCORE_MATCH_CONSECUTIVE, the
            # previous character MUST be a match

            match_required = i > 0 && j > 0 && m_table[i][j] == (d_table[i - 1][j - 1] + Fzy::SCORE_MATCH_CONSECUTIVE)
            positions[i] = j
            break
          end
        end
      end

      positions
    end
  end

  class PreparedHaystack
    getter haystack : Array(String)
    getter lower_haystack : Array(String)

    @empty_search_result : Array(Match)?
    @bonus : Array(Array(Float32)?)

    def initialize(@haystack : Array(String))
      @lower_haystack = @haystack.map(&.downcase)
      @bonus = Array(Array(Float32)?).new(@haystack.size, nil)
    end

    def bonus(index) : Array(Float32)
      bonus = @bonus[index]?
      return bonus unless bonus.nil?

      @bonus[index] = precompute_bonus(@haystack[index])
    end

    private def precompute_bonus(haystack) : Array(Float32)
      # Which positions are beginning of words
      m = haystack.size
      match_bonus = Array(Float32).new(m)

      last_ch = '/'

      Array(Float32).new(m) do |i|
        ch = haystack[i]
        match_bonus = if last_ch == '/'
                        SCORE_MATCH_SLASH
                      elsif last_ch == '-' || last_ch == '_' || last_ch == ' '
                        SCORE_MATCH_WORD
                      elsif last_ch == '.'
                        SCORE_MATCH_DOT
                      elsif last_ch.lowercase? && ch.uppercase?
                        SCORE_MATCH_CAPITAL
                      else
                        0_f32
                      end
        last_ch = ch
        match_bonus
      end
    end

    private def empty_search_result
      @empty_search_result ||= begin
        positions = [] of Int32
        @haystack.map { |e| Match.new(e, SCORE_MIN, positions) }
      end
    end

    def search(needle : String) : Array(Match)
      return empty_search_result if needle.empty?

      lower_needle = needle.downcase
      matches = [] of Match
      @lower_haystack.each_with_index do |lower_hay, index|
        next unless match?(lower_needle, lower_hay)

        matches << Match.new(needle, lower_needle, self, index)
      end
      matches
    end

    private def match?(needle : String, haystack : String) : Bool
      offset = 0
      needle.each_char do |nch|
        new_offset = haystack.index(nch, offset)
        return false if new_offset.nil?

        offset = new_offset + 1
      end
      true
    end
  end

  # Search a needle in a haystack and returns an array of matches.
  def search(needle : String, haystack : PreparedHaystack) : Array(Match)
    haystack.search(needle)
  end

  # Search a needle in a haystack and returns an array of matches.
  #
  # Consider using #search(String,PreparedHaystack) if you want to repeat this call with
  # different needles but the same haystack.
  def search(needle : String, haystack : Array(String)) : Array(Match)
    search(needle, PreparedHaystack.new(haystack))
  end
end
