require 'mechanize'
require 'pismo'

class String
  def is_number?
    true if Float(self) rescue false
  end
end

class Fixnum
  def is_number?
    true if Float(self) rescue false
  end
end

words = lambda {|k| !k.is_number?}
profile = ""
@agent = Mechanize.new
@agent.get("http://www.okcupid.com/profile/College-guy1")
@agent.page.search(".text").each do |item|
  profile << "\n #{item.text.strip} \n"
end

kw = Pismo[profile].keywords
kw.each do |this|
  p this.map &words

end
