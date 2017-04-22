class Util
  def self.gsubs(text, keywords)
    keywords.split(" ").each do |keyword|
      text = text.gsub(keyword, keyword.green)
    end
    text
  end

  def self.filter_tail(array, text)
    array.select {|member| member.end_with?(text) }
  end

  def self.has?(x, kws)
    kws = kws.split(" ")
    negs = kws.select {|kw| kw.start_with?("!") }.map{|kw| kw.gsub("!", "")}
    kws = kws.select {|kw| !kw.start_with?("!") }
    kws.select{|kw| x.include?(kw)}.size == kws.size && \
      negs.select{|kw| x.include?(kw)}.size == 0
  end
end  


