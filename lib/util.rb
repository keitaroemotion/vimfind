class Util
  require "colorize"
  class << self

    def paint(keywords, file)
      keywords.each { |keyword|
        file = file.gsub(keyword, keyword.green) if keyword.size > 1
      }
      file
    end

    def sort_keywords(keywords)
      [
        keywords.select {|k| k.start_with?("^") }.map{|k| k.gsub("^", "")},      
        keywords.select {|k| !k.start_with?("^") }
      ]  
    end
 
    def get_input
      input = $stdin.gets.chomp
      abort if input == "q"
      input
    end

    def vim_or_test(index, test, files)
      files[index] = files.first unless files.size > index
      command = "#{test ? "ruby -I test" : "vim"} #{files[index]}"
      puts command.green; system command
      print "\ndone. [press enter]: "
      !test || $stdin.gets.chomp
    end

    def read(file)
      File.read(file)
    rescue => e
      ""
    end

    def match?(regex, file)
      regex =~ read(file)
    rescue => e
      false
    end

    #
    # initially, files == original_files
    #
    def open(keywords, files, original_files, test = false)
      nons, keywords = sort_keywords(keywords)
      puts "\nkeywords: #{keywords}".cyan
      puts "nons: #{nons}".red

      if keywords.size > 0
        regex = Regexp.new("#{keywords.join('.*')}.*")
        puts "[regex: #{regex}] test: #{test} size: #{files.size} nons.size: #{nons.size}".yellow
        files = files.select { |file| /_test\.rb/ =~ file } if test
        files = files.select { |file| regex =~ file }
        files = Dir["./**/*"].select { |file| regex =~ file } if files.size == 0
      end  
      if nons.size > 0
        files = files.select { |file| nons.select{|non| file.include?(non)}.size == 0  }
      end  

      files.each_with_index { |file, i|
        puts "#{i} #{paint(keywords, file)}"
      }

      puts "\n[test mode: #{test ? 'on'.green : 'off'.red}]"
      puts "[q: quit     t: test       c: cmd           ]"
      puts "[a: all      -: diff       g: grep          ]"
      puts "[@: test all A: entire dir D: git diff range]"
      puts "[o: open index zero                         ]"
      puts "[,{@}: open the index with comma size       ]"
      print "> "

      input = get_input

      if /^[,]+$/ =~ input
        vim_or_test(input.size-1, test, files)
      elsif /^\s*$/ =~ input
        keywords = []
      elsif /^D\s*/ =~ input
        files = `git diff develop --name-only`
        keywords = input.gsub("D ", "").split(" ")
        original_files = files
      elsif /^A\s*/ =~ input
        files = Dir["./**/*"]
        keywords = input.gsub("A", "").strip.split(" ")
        original_files = files
      elsif /^o\s*$/ =~ input
        vim_or_test(0, test, files)
      elsif /^g\s/ =~ input
        regex = Regexp.new(input[1..-1].strip.gsub(" ", ".+"))
        puts "regex: #{regex.to_s.green}"
        files = Dir["./**/*"] if files.size == 0
        files = files
          .select { |file| File.file?(file) }
          .select { |file| match?(regex, file) }
        files = Dir["./**/*"] if files.size == 0
        files = files
          .select { |file| File.file?(file) }
          .select { |file| match?(regex, file) }
        puts "non found ".red if files.size == 0
        files = files
        files.each { |file|
          puts "[#{file}]".blue
          File.open(file, "r").each { |line| puts line[1..100].yellow if regex =~ line }
        }
        keywords = input[1..-1].strip.split(" ")
        return open(keywords, files, original_files, test)        
      elsif /^c\s*$/ =~ input
        system input.gsub(/^c\s/, "")
      elsif /^-\s*$/ =~ input
        system "git diff develop #{files.join(' ')}"  
      elsif /^a\s*$/ =~ input
        return open(input[1..-1].split(" "), original_files, original_files, test)        
      elsif /^t\s*$/ =~ input
        return open(
          input.split(" "),
          files,
          original_files,
          !test
        )
      elsif /^@/ =~ input
        files.each do |file|
          system "ruby -I test #{file}" if /_test\.rb$/ =~ file
        end
        keywords = []
      elsif /^\d+$/ =~ input
        vim_or_test(input.to_i, test, files)
      else  
        keywords = input.strip != "" ? input.split(" ") : keywords
      end  
      open(keywords, files, original_files, test)        
    end

    def num?(i)
      !/^[0-9]/.match(i).nil?
    end

    def check_order(files, ofiles)
      print "[enter number: ] ".magenta
      i = $stdin.gets.chomp
      files = files.select{|x| x.include?(i) }
      files = ofiles if files.size == 0
      files.each_with_index do |file, idx|
        puts "[#{idx.to_s.yellow}]: #{file.gsub(i.to_s, i.to_s.green)}"
      end
      if num?(i) || files.size == 1
        File.open("#{files[i.to_i]}", "r").each_line.to_a.select do |line|
          line.strip.start_with?("def ") || line.strip.start_with?("test ")
        end.each do |line|
          puts line.strip.chomp.cyan
        end
      else
        return check_order(files, ofiles)
      end
    end

    def compare_methods(current_dir, method_name)
      result = Dir["#{current_dir}/**/*"].map do |file|
        if File.directory?(file)
        else
          compare_methods_sub(file, method_name)
        end  
      end.select {|x| x != nil}

      display(result, method_name, "")
    end

    def display(result, method_name, kws)
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

    def sc(line)
      line.strip.chomp
    rescue
      ""
    end

    def sw(line, method_name)
      key = "def #{method_name}"
      line = line.strip
      line == key || line.start_with?("#{key}\n") || line.start_with?("#{key}(")
    end

    def compare_methods_sub(file, method_name)
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

    def cleansing_target_line(line, count)
      line = line.chomp
      if line.end_with?(" ")
        [line.rstrip, count + 1]
      else
        [line, count]
      end
    end  

    def clean(files)
      result = []
      files.select{|f| File.exist?(f) }.each do |file|
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

    def extra_option(opt)
      opt = opt.strip
      if opt == ":t"
        Test.testare $files_all
        return true
      elsif opt == ":e"
        puts "\nyou are already in the edit mode\n".magenta
        return false
      end
    end    

    def extra_option_2(opt)
      opt = opt.strip
      if opt == ":e"
        open_file "",  $files_all
        return true
      elsif opt == ":t"
        puts "\nyou are already in the test mode\n".magenta
        return false
      end
    end    

    def index
      print "\n[enter number: /all :t :e :d :c :o] "
      choice = $stdin.gets.chomp
      abort if choice.downcase == "q"
      choice.strip
    end

    def grep(files, kw)
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

    def gsubs(text, keywords)
      keywords.split(" ").each do |keyword|
        text = text.gsub(keyword, keyword.green)
      end
      text
    end

    def filter_tail(array, text)
      array.select {|member| member.end_with?(text) }
    end

    def has?(x, kws)
      x = x.downcase
      kws = kws.split(" ").map{|y| y.downcase }
      negs = kws.select {|kw| kw.start_with?("!") }.map{|kw| kw.gsub("!", "")}
      kws = kws.select {|kw| !kw.start_with?("!") }
      kws.select{|kw| x.include?(kw)}.size == kws.size && \
        negs.select{|kw| x.include?(kw)}.size == 0
    end
  end
end  


