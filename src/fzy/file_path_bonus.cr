module Fzy
  # :nodoc:
  SCORE_MATCH_SLASH = 0.9_f32
  # :nodoc:
  SCORE_MATCH_WORD = 0.8_f32
  # :nodoc:
  SCORE_MATCH_CAPITAL = 0.7_f32
  # :nodoc:
  SCORE_MATCH_DOT = 0.6_f32

  # File path based bonus function.
  # Increase the match score on a match after a slash, '-', '_' and ' ',
  # '.' or a upper case letter after a lower case one.
  def self.file_path_bonus(item : String, i : Int32) : Float32
    last_ch = i.zero? ? '/' : item[i - 1]
    ch = item[i]

    if last_ch == '/'
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
  end
end
