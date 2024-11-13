require "./hay"

module Fzy
  # :nodoc:
  SCORE_MIN = -Float32::INFINITY
  # :nodoc:
  SCORE_MAX = Float32::INFINITY
  # :nodoc:
  SCORE_GAP_LEADING = -0.005_f32
  # :nodoc:
  SCORE_GAP_TRAILING = -0.005_f32
  # :nodoc:
  SCORE_GAP_INNER = -0.01_f32
  # :nodoc:
  SCORE_MATCH_CONSECUTIVE = 1.0_f32

  # A search operation returns an array of Match objects.
  # See `Fzy.search`
  class Match(T)
    include Comparable(Match)

    getter hay : Hay(T)
    # Array of size of needle string, containing the position of each needle character into haystack string.
    getter positions : Array(Int32)?
    # Match score.
    getter score : Float32

    def initialize(downcase_needle : String, @hay : Hay(T), store_positions : Bool = false)
      n = downcase_needle.size
      m = @hay.key.size

      if n.zero? || m.zero? || m > 1024
        # Unreasonably large candidate: return no score
        # If it is a valid match it will still be returned, it will
        # just be ranked below any reasonably sized candidates
        @score = SCORE_MIN
        @positions = Array.new(n, -1) if store_positions
      elsif n == m
        # Since this method can only be called with a haystack which
        # matches needle. If the lengths of the strings are equal the
        # strings themselves must also be equal (ignoring case).
        @score = SCORE_MAX
        @positions = Array.new(n) { |i| i } if store_positions
      else
        d_table = Array.new(n, [] of Float32)
        m_table = Array.new(n, [] of Float32)
        compute_match(d_table, m_table, n, m, downcase_needle)

        @positions = find_positions(n, m, d_table, m_table) if store_positions
        @score = m_table[n - 1][m - 1]
      end
    end

    # A match is greater than other if it has a greater score.
    def <=>(other : Match)
      cmp = other.score <=> @score
      return other.item <=> @hay.item if cmp == 0 && T < Comparable

      cmp
    end

    delegate item, to: @hay

    private def compute_match(d_table, m_table, n, m, downcase_needle)
      # d_table[][] Stores the best score for this position ending with a match.
      # m_table[][] Stores the best possible score at this position.

      downcase_hay = @hay.key
      bonus = @hay.bonus

      prev_score = SCORE_MIN
      n.times do |i|
        d_table[i] = Array.new(m, 0_f32)
        m_table[i] = Array.new(m, 0_f32)

        prev_score = SCORE_MIN
        gap_score = i == n - 1 ? SCORE_GAP_TRAILING : SCORE_GAP_INNER

        m.times do |j|
          if downcase_needle[i] == downcase_hay[j]
            score = SCORE_MIN
            if i.zero?
              score = (j * SCORE_GAP_LEADING) + bonus[j]
            elsif j > 0 # i > 0 && j > 0
              score = Math.max(
                m_table[i - 1][j - 1] + bonus[j],
                # consecutive match, doesn't stack with bonus
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

    private def find_positions(n : Int32, m : Int32, d_table, m_table) : Array(Int32)
      positions = Array.new(n, -1)

      # backtrack to find the positions of optimal matching
      match_required = false

      i_iterator = (n - 1).downto(0)
      j_iterator = (m - 1).downto(0)

      i_iterator.each do |i|
        j_iterator.each do |j|
          # There may be multiple paths which result in
          # the optimal weight.
          #
          # For simplicity, we will pick the first one
          # we encounter, the latest in the candidate
          # string.
          if (d_table[i][j] != SCORE_MIN) && (match_required || d_table[i][j] == m_table[i][j])
            # If this score was determined using
            # SCORE_MATCH_CONSECUTIVE, the
            # previous character MUST be a match

            match_required = i > 0 && j > 0 && m_table[i][j] == (d_table[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE)
            positions[i] = j
            break
          end
        end
      end

      positions
    end
  end
end
