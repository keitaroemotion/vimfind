require 'colorize'
require '/usr/local/lib/vf/func_sort.rb'

class VimFind

  attr_reader 

  GREP = "?"
  LIST = %w(def concerning belongs_to has_one has_many test)
  WIKIDIR =  "/usr/local/etc/vimfind/wiki"  

  def initialize(params)
    @params   = params
    @terms    = terms
    @mvc_mode = mvc_mode
  end

  def option
    @params[0]
  end

  def disp_instruction() abort "\nyou need argument.\n".red end

  def add_test(arr)
    arr + arr.map {|a| "test/#{a}"}
  end

  def terms
    @params.size > 0 ? @params : disp_instruction
  end  

  def mvc_mode
    if @params.include?("-mvc") 
      add_test(["controllers","models","views", "backends"]) 
    else  
      []
    end  
  end

  def get_directory
    begin
      dir = @params.select {|arg| File.directory?(arg) }
      dir.size == 0 ? Dir.pwd : dir[0]
    rescue
      "."
    end
  end

  def directory
    "#{get_directory}/**/*".gsub("//","/") 
  end  

  def file_open(file, mode)
    File.open(file, mode).read.downcase rescue ""
  end

  def get_words(terms)
    terms.select{|term| term.start_with?(GREP)}
      .map{|term| term.gsub(GREP,"")}
  end

  def get_non_words(terms)
    terms.select{|term| !term.start_with?(GREP)}
  end

  def has_words(terms, text)
    (terms.select{|term| text.include?(term)}.size == terms.size) \
      && (terms.size > 0)
  end

  def is_term_in_file(file, terms)
    has_words(terms, file_open(file, "r"))
  end

  def includes(file, terms, words_in_file_name=true, words_in_file_content=true)
    non_terms = get_non_words(terms) 
    terms     = get_words(terms)
    words_in_file_content =
      File.file?(file) && is_term_in_file(file, terms) if terms.size > 0
    words_in_file_name = non_terms.select{ |term|
                           if term.start_with?("^")
                             file.downcase.include?("/"+term.gsub("^",""))
                           else
                             file.downcase.include?(term)
                           end
                         }.size == non_terms.size if non_terms.size > 0
    words_in_file_name && words_in_file_content                      
  end

  def replace(text, terms)
    terms.each { |term| text = text.gsub(term, "#{term.green}") }
    text
  end

  def list_files(dir, terms, mvc)
    Dir.glob(dir).select{|file| includes(file, terms) }
  end

  def display_matches(f, terms)
    File.open(f, "r").each_with_index do |item, index|
      print replace("#{item}", terms) if  has_words(terms, item) 
    end if File.file?(f)
  end

  def sort(files, i, new_files=[])
    files = files.flatten 
    [i-1..files.size-1].each {|x| new_files.push(files[x])}
    [0..i-2].each {|x| new_files.push(files[x])}
    new_files.flatten
  end


  def paint(t, f)
    puts t.cyan if t.start_with?(LIST[0])
    puts t.blue if t.start_with?(LIST[1])
    (2..4).each do |i|
      puts File.basename(f).gsub(".rb"," ").magenta + t.magenta if t.start_with?(LIST[i])
    end
    puts t.green if t.start_with?(LIST[5])
  end

  def tmpsearch(f, term, res=[], key="def")
    File.open(f, "r").each do |line|
      return res.map{|x| x.chomp} if (res.size > 0 && line.include?("def "))
      res.push(line) if (line.include?("#{key} "+term) || res.size > 0)
    end
    return res.map{|x| x.chomp }
  end

  # this part is pretty dirty ( we need to clean this up later)
  # this function allows you to enlist function name only in
  # the current selected file:
  # this allows you to show only functions and Concerns, test labels
  # without entering into the file.

  def collect_funcs(f, result=[])
    lines = File.open(f, "r").each_line.to_a if File.file?(f)
    result.push cf_subroutine(lines) if lines
    result.flatten.each_slice(5).each_with_index do |lines, i|
      lines.each do |line|
        paint(line.strip, f)
      end
      if i > 0
        print "[q:quit text:code bloc search None:Go next] "
        command = $stdin.gets.chomp.strip
        case command
        when "q"
          abort
        when ""
        else
          tmpsearch(f, command).each do |line|
            puts line.yellow
          end
        end 
      end  
    end
  end

  def cf_subroutine(lines, new_lines=[])
    lines.each do |line|
      LIST.each {|x| new_lines.push(line) if line.strip.start_with?(x) }
    end
    new_lines.select {|x| x }
  end

  def get_table_name(res, key)
    res[0].gsub(key, "").gsub("\"","").split(",")[0].strip
  end

  def parse_value(value)
    value[1..value.size-1].map{|x| x.chomp.gsub("t.","")}
  end

  def get_command(msg)
    print msg
    $stdin.gets.chomp
  end

  def check_db(dir, key="create_table ", res=[], hash={})
    File.open(list_files(dir, %w(db schema.rb), [])[0], "r").each do |line|
      if (res.size > 0 && line.include?("end"))
        hash[get_table_name(res, key)] = parse_value(res)
        res = []
      end  
      res.push(line) if (line.include?(key) || res.size > 0)
    end
    command = get_command "[Enter:]"
    case command
    when ""
      hash.keys.each {|k| puts k.red }
    else
      keys   = hash.keys.include?(command) ? [command] : nil
      keys   = hash.keys.select{|k| k.include?(command)} if !keys
      keys  += hash.keys.select{|k| hash[k].select{|v| v.include?(command)}.size > 0 && !keys.include?(k) } 
      keys.each do |key|
        puts "|#{key}|".cyan
        hash[key].tap {|v| puts v.map{|x| x.sub(command, command.cyan)}}
        $stdin.gets.chomp 
      end
    end
  end

  def ask_no_abort(msg, f, terms, a=false)
    print "#{msg} "
    input = $stdin.gets.chomp.strip
    return nil if input == "q" || input == ""
    a ? input.split(" ") : input
  end

  def ask(msg, f, terms, a=false)
    print "#{msg} "
    input = $stdin.gets.chomp
    abort if input == "q"
    test(f, terms) if input == ""
    a ? input.split(" ") : input
  end

  def contains(a, b)
    a.select{|x| x == b }.size > 0
  end

  def text_has(arr, line)
    arr.select{ |x| line.downcase.include?(x.downcase) }.size > 0
  end

  def share_nothing(a1, a2)
    a1.select{|x| a2.include?(x) }.size == 0
  end

  def survey_test(test_file)
    target_file = "app/#{test_file[5..-1]}".gsub("_test.rb",".rb")
    test_lines = File.read(test_file)
    functions = File.read(target_file).each_line
      .map {|line| line.strip }
      .select { |line| line.start_with?("def ")}
      .select { |func| !test_lines.include?(func) }
      .map {|func| func.gsub("def ", "" )}
    puts functions  
  end

  def unit_test(commands, f, options)
    terms = commands.select{|x| !options.include?(x)}
    lines = File.read(f).split("\n").select{ |line|
      line = line.strip
      line.include?("test ") && line.include?("do") && !line.start_with?("#") &&
      (text_has(terms, line) || terms.size == 0) 
    }.map{ |test|
      test.gsub("test","").gsub("\"","").gsub("do", "").gsub('|','\|')
    }
    return "Nothing Found" if lines.size == 0
    lines.each_with_index { |test, i|
      puts "[#{i}] #{test.strip}" 
    }
    term = fix_label(lines[ask('[Enter Number]', f, terms).to_i].strip) 
    "-n /.*#{term}.*/"
  end

  def test(f, terms, term="")
    unless f.end_with?("_test.rb")
      puts "Hey, this is not test file.".magenta
      return 
    end

    v = "--verbose"
    if term == ""
      options=["t", "u", "c", "q"]
      commands = ask_no_abort(
        "[t:test_all][u:unit_test]" +
        "[c:check][q:quit]",
        f,
        terms,
        true
      )
      puts "commands| #{commands}"
      return if !commands || commands.select{|x| options.include?(x)}.empty? 
      test(f, terms) if share_nothing(commands, options)
      v = contains(commands, "t") ? "--verbose" : ""
      if commands.include?("u")
        term = unit_test(commands, f, options)
      end  

      if commands.include?("c")
        survey_test f
        return
      end  
    end

    command = "bundle exec ruby -I test #{f} #{term} #{v}"
    puts command.green
    system command
    system "fplay /System/Library/Sounds/Glass.aiff"
  end

  def format_into_mac(t)
    t.chomp.gsub('(','\(').gsub(')','\)').gsub(" ",'\ ')
  end

  def fix_label(label)
    label.include?("  ") ? fix_label(label.gsub("  ", " ")) : label.gsub(" ","_")
  end

  def is_source(line)
    [".rb", ".xml", ".js", ".html", ".erb"].each do |ext|
      return true if line.end_with?(ext)
    end
    return true if File.directory?(line)
    return false
  end

  def open_https(f)
    puts f.green 
    vim_targets = []
    File.open(f, "r").each_line do |line|
      if File.exist?(line.strip)
          if is_source(line.strip)
            vim_targets.push "#{format_into_mac(line.strip)}" 
          else
            system "open #{format_into_mac(line.strip)}" 
          end
      elsif File.exist?(format_into_mac(line.strip))
          system "open #{format_into_mac(line)}"
      else
        line.split(' ').each do |token|
          token = format_into_mac(token.chomp)
          system "open #{token}" if (token.start_with?("http"))
        end
      end
    end
    system vim_targets.uniq.inject("vim "){|a, b| "#{a} #{b}"} if vim_targets.size > 0
  end

  def add_file_to_wiki(f)
      print "[TERM] "
      system "echo #{f} >> #{WIKIDIR}/#{$stdin.gets.chomp}" 
  end

  def open_test(f, exe=false)
    test_name = File.basename(f).gsub(".rb","_test.rb")
    Dir["**/#{test_name}"].each do |test_file|
      if exe 
        system "bundle exec ruby -I test #{test_file}"
      else
        system "vim #{test_file}"
      end
    end
  end

  def execute_file(dir, files, f, index, mvc_keyword, terms, next_flag=false)
    if (!mvc_keyword || file_open(f, "r").include?(mvc_keyword))
      file_path = replace(f, terms)
      puts "dir:  [#{replace(File.dirname(f), terms)}]"
      puts "file: [#{replace(File.basename(f), terms)}] ?"
      puts "[v: open with vim    ][q: quit                ]".cyan
      puts "[w: show grep result ][s: search another file ]"
      puts "[l: list methods     ][d: db schema search    ]"
      puts "[t: execute test     ][f: file sort           ]"
      puts "[o: open file        ][a: add file to wiki    ]"
      puts "[ct: open corresponding test with vim]".yellow
      puts "[ce: execute corresponding test]".magenta
      puts "[r: rubocop search   ][b: blame               ]"

      print "[p:prev n:next] Enter: ".cyan
      input = $stdin.gets.chomp.downcase
      open_test(f) if input == "ct"
      open_test(f, true) if input == "ce"
      check_db(dir)                 if input == "d"
      system "vim #{format_into_mac(f)}"             if (input == "y" || input == "v")
      open_file(f)                  if input == "o"
      system "rubocop #{f}"         if input == "r"
      add_file_to_wiki(f)           if input == "a"
      display_matches(f, key_terms) if input == "w"
      collect_funcs(f)              if input == "l"
      test(f, terms, "t")                if input == "t"
      test(f, terms, "t")           if input == "tt"
      open_https(f)                 if input == "u"
      system "git blame #{f}"       if input == "b"
      execute_files(sort(files, index), mvc_keyword, terms, dir) if input == "p"
      abort                         if input == "q"
      next_flag = true              if input == "n"
      FuncSort.sort(f)              if input == "f"
      if input == "s"
        print "[term:] "
        search_all($stdin.gets.chomp.split(' '), dir, [], mvc_keyword) 
      end
      execute_file(dir, files, f, index, mvc_keyword, terms) unless next_flag
    end
  end

  #
  # needs refactoring with this shitty boiler plate
  #
  def execute_files(files, mvc_keyword, terms, dir, i=0)
    key_terms = get_words(terms)
    if terms.size == 1
      puts terms
      files.select{|x| File.basename(x).start_with?(terms[0])}.each_with_index do |f, index|
        execute_file dir, files, f, index, mvc_keyword, terms
      end
      files.select{|x| !File.basename(x).start_with?(terms[0])}.each_with_index do |f, index|
        execute_file dir, files, f, index, mvc_keyword, terms
      end
    else
      files.each_with_index do |f, index|
        execute_file dir, files, f, index, mvc_keyword, terms
      end
    end  
  end

  def open_file(f)
    basename = format_into_mac(File.basename(f))
    system "open #{File.dirname(f)}/#{basename}"
  end

  def search_all(terms=nil, dir=nil, mvc=false, mvc_keyword="")
    terms ||= @terms 
    dir   ||= directory
    execute_files list_files(dir, terms, mvc), mvc_keyword, terms, dir
  end

  def enlist_wiki(wikidir, arg)
    system "ls #{wikidir}" if !arg 
    look_for_similar_file(wikidir, arg) if arg
  end

  def look_for_similar_file(dir, tag)
    Dir["#{dir}/*"].each do |file|
      if File.basename(file).start_with?(tag)
        print "#{File.basename(file)}[Y/n]? "
        return file if $stdin.gets.chomp.downcase == "y"
      end
    end
    abort "done:"
  end

  def get_term(cmd, wikidir)
    term = cmd
    print "[term:] " if !cmd
    term =  $stdin.gets.chomp if !cmd
    if cmd == ":r"
      ls = Dir["#{wikidir}/*"]
      term = File.basename ls[Random.rand(ls.size-1)] 
    end
    term
  end

  def open(cmd, wikidir)
      term = get_term(cmd, wikidir)
      wikifile =  "#{wikidir}/#{term}"
      wikifile = look_for_similar_file(wikidir, term) if !File.exist?(wikifile)
      open_https(wikifile)
  end

  def supply(file)
    original_file = file
    file = "#{Dir.pwd}/#{file}" 
    file = original_file            if !File.exist?(file)
    abort "#{file} does not exist." if !File.exist?(file)
    file
  end

  def operate_wiki
    system "mkdir -p #{WIKIDIR}"
    if @params[1] == ":ls" || @params[1] == nil
      enlist_wiki(WIKIDIR, @params[2])
    elsif @params[1] == "o" 
      open(@params[2], WIKIDIR)
    else
      wikifile =  "#{WIKIDIR}/#{@params[1]}"
      system "echo #{supply(@params[2])} >> #{wikifile}" if @params[2]
      system "vim #{wikifile}" if !@params[2]
    end
  end
end 
