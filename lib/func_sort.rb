module Lib
  class FuncSort
    def self.has_terms?(line, terms)
      !(terms.select do |term|
         strip(line).start_with? term
        end).empty?
    end

    def self.end_of_a_method(line, count, name_space_count)
      line == "end" && (count < name_space_count)
    end

    def self.private_array(lines, name_space_count, pub=false)
      unless pub
        lines = lines.reverse
      end  
      count = 0
      methods = []
      lines.map{ |line| strip(line) }.each do |line|
        if end_of_a_method(line, count, name_space_count)
          count += 1
        elsif line == "private"
          methods = methods.last == "" ? methods[0..-2] : methods 
          return pub ? methods : methods.reverse    
        else
          methods.push line
        end  
      end
      methods
    end

    def self.methods(lines)
      indents = method_indents(lines)

      flag = false
      target      = []
      targets     = []
      non_targets = []

      lines.each do |line| 
        if /^#{indents}def\s.*/.match(line)
          flag = true
          target.push "\n"+line
        elsif /#{indents}end.*/.match(line)
          flag = false
          targets.push target
          target = []
        elsif flag
          target.push line
        else
          non_targets.push line
        end
      end 

      targets = targets.map do |target|
        target + ["#{indents}end"]
      end

      [targets.sort, non_targets]
    end

    def self.private_defs(lines)
      _lines = []
      flag = true
      lines.reverse.each do |line|
        if line.strip == "private"
          flag = false 
        end
        _lines.push(line) if flag
      end
      
      _lines.select do |line|
        /(def|module|class)\s.*/.match(line.strip)
      end
    end

    def self.sort_class(str) 
      indents = method_indents(defs(str))

      pub_methods = get_methods(str, true)
      pri_methods = get_methods(str, false)

      to_sort     = false
      delimiter = "#{indents}$code_block_moomin" 
      sorted_class = str.map do |line|
        if /#{indents}def\s.*/.match(line) && !to_sort
          to_sort = true
          delimiter
        elsif !to_sort
          line
        elsif to_sort && /^#{indents.gsub("  ", " ")}end/.match(line)
          to_sort = false
          line
        else
        end
      end

      body = pub_methods.join("\n") +
             "\n\n#{indents}private\n" +
             pri_methods.join("\n")

      fit_lines(fit_eol(add_ends((sorted_class.join("\n") + "\n")
        .gsub(delimiter, body))))
    end

    def self.add_ends(str)
      tail = str.split("\n").last
      if /^[\s]*end/.match(tail) 
        add_ends(str + "\n" + /^[\s]*end/.match(tail).to_s[2..-1])
      else
        str
      end
    end

    def self.maximum(lines)
      lines.select do |line|
         /\s*def.*/
          .match(line)
      end.map do |line|
        line.split("def ")[0].size
      end.max
    end

    def self.method_indents(klass_str)
      " ".rjust(maximum(klass_str))
    end

    def self.include?(arr, x)
      arr.select do |a|
        x[0].include?(a)
      end.size > 0
    end

    def self.fit_eol(body)
      body.include?(" \n") ? fit_eol(body.gsub(" \n", "\n")) : body
    end

    def self.fit_lines(body)
      body.include?("\n\n\n") ? fit_lines(body.gsub("\n\n\n", "\n\n")) : body
    end

    def self.get_methods(str, is_public)
      methods(str)[0]
        .select do |x| 
           included = include?(private_defs(str), x)
           is_public ? !included : included
        end
    end

    def self.defs(lines)
      lines.select {|line| /(def|module|class)\s.*/.match(line) }
    end

    def self.sort_top_methods(lines)

    end

    def self.private_methods
    end

    def self.is_not_dup_blank_lines(lines, index)
      index == 0 || !(lines[index - 1].strip == lines[index].strip &&
        lines[index].strip == "") 
    end

    def self.remove_space_line_duplication(lines)
      new_lines = []
      lines.each_with_index do |line, index|
        if is_not_dup_blank_lines(lines, index)
          new_lines.push line
        end
      end
      lines
    end

    def self.wash_lines(lines)
      lines = remove_space_line_duplication(lines)
      lines.map {|line| line.rstrip }
    end

    def self.get_lines(file)
      lines = File.read(file).each_line.to_a
      lines_r = lines.reverse
      tab = "  "
      name_space_count = lines_r
        .select do |line|
          has_terms?(line, ["class", "module"])  
        end.size
        
      tops = private_array(lines, 0).reverse

      private_tag = lines_r.select {|line| line.strip == "private" }

      privates = 
        privates_to_hash(
          private_array(lines_r, name_space_count)
        ).map do |_key, value|
          value.join
        end

      bottoms = (name_space_count .. 1).map do |index|
        ([tab] * (index - 1)).join + "end"
      end

      formatted_data =
        trim_dup_ln((tops + [private_tag] + privates + bottoms).flatten
        .inject(""){|acc, line| acc + line })
      puts "-------------------------------"  
      puts formatted_data  
      puts "-------------------------------"  
      puts "Okay? [Y/n]: "
      if $stdin.gets.chomp.downcase == "y"
        f = File.open(file, "w")
        f.puts formatted_data
        f.close
      end
    end

    def self.trim_dup_ln(text)
      text.include?("\n\n\n") ? trim_dup_ln(text.gsub("\n\n\n", "\n\n")) : text
    end

    def self.privates_to_hash(privates)
      blobs = {}
      blob = []
      privates.reverse.each do |line|
        blob.push line
        if line.strip.start_with?("def ")
          func_name = line.strip.gsub("def ", "") 
          blobs[func_name] = (blob + ["\n"]).reverse
          blob = []
        end
      end
      Hash[ blobs.sort_by { |key, val| key } ]
    end

    def self.strip(line)
      line.strip rescue line
    end

    def self.sort(file)
      get_lines file  
    end
  end
end
