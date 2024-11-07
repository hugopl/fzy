module Fzy
  BonusProc = Proc(String, Array(Float32))

  # :nodoc:
  SCORE_MATCH_SLASH = 0.9_f32
  # :nodoc:
  SCORE_MATCH_WORD = 0.8_f32
  # :nodoc:
  SCORE_MATCH_CAPITAL = 0.7_f32
  # :nodoc:
  SCORE_MATCH_DOT = 0.6_f32

  # Match bonus used when doign fzy search on file paths.
  #
  # Add bonus when:
  # - A slash matches.
  # - A match after a `_`, `-`, ' ' or `.`.
  # - A match after a case change.
  def filepath_bonus(key : String) : Array(Float32)
    # Which positions are beginning of words
    m = key.size
    match_bonus = Array(Float32).new(m)

    last_ch = '/'
    Array(Float32).new(m) do |i|
      ch = key[i]
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
end
