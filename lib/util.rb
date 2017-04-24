class Util
  def self.grep(files)
    kw = ARGV[1]
    if kw.nil?
      print "[Enter Keyword: ] " 
      kw = $stdin.gets.chomp
    end
    files.each do |file|
      content = File.open(file, "r").each_line.to_a.join.downcase 
      if content.include?(kw.downcase)
        puts file.magenta
      end
    end
  end

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


