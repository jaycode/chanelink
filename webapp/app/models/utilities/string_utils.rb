# useful string utilities
class StringUtils

  # scramble a text into random strings
  def self.scramble(text)
    if text.length <= 8
      s = StringIO.new
      text.length.times do
        s << 'X'
      end
      s.string
    else
      s = StringIO.new
      s << text[0,3]
      (text.length - 6).times do
        s << 'X'
      end
      s << text[text.length - 3,3]
      s.string
    end
  end

end
