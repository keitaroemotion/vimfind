class Util
  def self.open_file(kws, files)
    alert = ""
    return if extra_option(kws)
    files = files.select{|x| Util.has?(x, kws) } if !kws.nil?
    if files.size == 0
      alert = "\n\nnon found\n\n".red
      files = $files_all
    end
    (files || []).each_with_index do |file, i|
      puts "#{i.to_s.cyan}: #{Util.gsubs(file, kws)}"
    end
    print alert
    i = Util.index
    return if extra_option(i)
    if i == ":d"
      base_dir = []
      dirs = files.select{|f| File.directory?(f)}
      dirs.each_with_index do |dir, i|
        if base_dir.select{|d| dir.include?(d) }.size > 0
        else
          print "[DIR #{i}] ".green
          puts dir.magenta
          base_dir.push dir
        end  
      end
      print "[enter:] "
      key = $stdin.gets.chomp
      dir_con = Dir["#{dirs[key.to_i]}/**/*"]
      abort "[BLANK]: #{dirs[key.to_i]}".red if dir_con.empty?
      return open_file("", dir_con)
    end
    files ||= Dir["**/*"]
    if !/^[0-9]/.match(i).nil? || files.size == 1
      system "vim #{files[i.to_i]}"
    else
      open_file i, files
    end
  end

  def self.compare_methods(current_dir, method_name)
    result = Dir["#{current_dir}/**/*"].map do |file|
      if File.directory?(file)
      else
        compare_methods_sub(file, method_name)
      end  
    end.select {|x| x != nil}

    display(result, method_name, "")
  end

  def self.display(result, method_name, kws)
    if method_name.nil?
      abort "\nyou need argument\n".red
    end

    result = result.flatten.select{|x| !x.nil? }
      .map {|x| x.gsub("def #{method_name}", "def #{method_name.green}")}
      .uniq

    result.each do |x|
        if kws == ""
          puts x
        else
          if kws.class == Array
            kws = kws.join(" ")
          end
          kws = kws.strip 
          filename = x.split("\n").first
          kws = kws.include?(" ") ? kws.split(" ") : [kws]
          if kws.select{|kw| x.include?(kw)}.size == kws.size
            puts x
          end
        end  
      end

    puts
    print "[keyword:] "
    input1 = $stdin.gets.chomp.downcase
    if input1 == "q"
      abort
    else
      display(result, method_name, input1) 
    end  
  end

  def self.sc(line)
    line.strip.chomp
  rescue
    ""
  end

  def self.sw(line, method_name)
    key = "def #{method_name}"
    line = line.strip
    line == key || line.start_with?("#{key}\n") || line.start_with?("#{key}(")
  end

  def self.compare_methods_sub(file, method_name)
    count_flag = false
    defs = 0
    content = "" 

    return nil unless file.end_with?(".rb")

    File.open(file, "r").to_a.each do |line|
      begin 
        if sw(line, method_name)
          content = "\n[#{file.magenta}]\n" 
          count_flag = true
        end

        if count_flag
          content += line
          if (
            (
              sc(line).start_with?("def") || \
              sc(line).start_with?("if ") || \
              sc(line).start_with?("begin ") || \
              sc(line).end_with?(" begin") || \
              sc(line).start_with?("unless ") || \
              sc(line).include?(" do ") || \
              sc(line).end_with?(" do")
            ) && \
            !sw(line, method_name)
          )
            defs += 1
          elsif (sc(line).start_with?("end") && defs > 0)  
            defs -= 1
          elsif (sc(line).start_with?("end") && defs == 0) 
            return content
          end
         end  
       rescue
          return nil 
       end
    end
    return content
  end

  def self.cleansing_target_line(line, count)
    line = line.chomp
    if line.end_with?(" ")
      [line.rstrip, count + 1]
    else
      [line, count]
    end
  end  

  def self.clean(files)
    result = []
    files.each do |file|
      count = 0
      clean_text =
        File.open(file, "r").map do |line|
          line, count = cleansing_target_line(line, count)
          "#{line}\n"
        end.inject(:+)
      File.open(file, "w") do |f|
        f.puts clean_text
      end
      result.push [file, count]
    end
    result.each do |file, count|
      puts "#{file}: #{count.to_s.green}" if count > 0
    end
  end

  def self.extra_option(opt)
    opt = opt.strip
    if opt == ":t"
      Test.testare $files_all
      return true
    elsif opt == ":e"
      puts "\nyou are already in the edit mode\n".magenta
      return false
    end
  end    

  def self.extra_option_2(opt)
    opt = opt.strip
    if opt == ":e"
      open_file "",  $files_all
      return true
    elsif opt == ":t"
      puts "\nyou are already in the test mode\n".magenta
      return false
    end
  end    

  def self.index
    print "\n[enter number: /all :t :e :d] "
    choice = $stdin.gets.chomp
    abort if choice.downcase == "q"
    choice.strip
  end

  def self.grep(files, kw)
    c = 0
    if kw.nil?
      print "[Enter Keyword: ] " 
      kw = $stdin.gets.chomp
    end
    files
      .select{|f| /(.png|.jpg|.gif|.log|.cache|.pdf|.xls|.exe|.ttf|.ico)/.match(f).nil? }
      .select{|f| File.file?(f)}
      .each do |file|
        begin
          content = File.open(file, "r").each_line.to_a.join.downcase 
          if content.include?(kw.downcase)
            print "[GREP] ".green
            puts file.magenta
            c = c+1
          end
        rescue
          puts "FAILED: #{file}".red   
        end
    end
    puts "\nFIN.\n".cyan
    c
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
    x = x.downcase
    kws = kws.split(" ").map{|y| y.downcase }
    negs = kws.select {|kw| kw.start_with?("!") }.map{|kw| kw.gsub("!", "")}
    kws = kws.select {|kw| !kw.start_with?("!") }
    kws.select{|kw| x.include?(kw)}.size == kws.size && \
      negs.select{|kw| x.include?(kw)}.size == 0
  end
end  


