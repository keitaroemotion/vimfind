module Lib
  class FuncSort
    def self.has_terms?(line, terms)
      !(terms.select do |term|
         strip(line).start_with? term
        end).empty?
    end

    def self.private_methods(lines_r, name_space_count)
      methods = []
      count = 0
      lines_r.each do |line|
        sline = strip(line)
        if sline == "end" && (count < name_space_count)
          count +=1            
        elsif sline == "private"
          return methods.reverse    
        else
          methods.push line
        end  
      end
      methods
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
        
      tops = private_methods(lines, 0).reverse

      private_tag = lines_r.select {|line| line.strip == "private" }

      privates = 
        privates_to_hash(
          private_methods(lines_r, name_space_count)
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
