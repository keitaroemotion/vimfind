require 'colorize'
require '/usr/local/lib/vf/func_sort.rb'

class VimFind

  #
  # XXX this fucking messy code must be refactored
  #     sooner or later
  #

  attr_reader 

  GREP = "?"
  LIST = %w(def concerning belongs_to has_one has_many test)
  WIKIDIR =  "/usr/local/etc/vimfind/wiki"  

  def initialize(params, debug_mode = nil)
    @params   = params
    @terms    = terms
    @diff_only = false
    if params.include?("-do")
      @diff_only = true
      @terms = @terms.select{|x| x != "-do"}
    end
    @debug_mode = debug_mode
  end

  def virtual_path
    "/usr/local/etc/vf/virtual_branch"
  end

  def virtual_branch
    system "mkdir -p /usr/local/etc/vf"
    system "touch #{virtual_path}" unless File.exist?(virtual_path)
    File.open(virtual_path, "r").to_a.first.strip
  rescue
    nil
  end

  def virtual_files
    branch = virtual_branch
    if branch.size == 0
      return []
    end
    `git diff --name-only #{branch}`.split("\n").map do |file|
      "#{file} #{branch}"
    end
  end

  def set_virtual
    p = `git branch`.split("\n")
    p.each_with_index do |branch, i|
      puts "[#{i}] #{branch}"
    end
    branch = p[ask_simple("[number:]").to_i]
    system "mkdir -p /usr/local/etc/vf"
    system "echo #{branch} > #{virtual_path}"
    print "[Your Current Virtual Branch is: ] ".green
    system "cat #{virtual_path}" 
  end

  def refer(file)
    command = "git show #{virtual_branch}:#{file}"
    puts command.green
    system command
  end

  def option
    @params[0]
  end

  def first_arg
    @params[1]
  end

  def disp_instruction() abort "\nyou need argument.\n".red end

  def add_test(file_names)
    file_names + file_names.map {|file| "test/#{file}"}
  end

  def terms
    @params.size > 0 ? @params : disp_instruction
  end  

  #def mvc_mode
  #  if @params.include?("-mvc") 
  #    add_test(["controllers","models","views", "backends"]) 
  #  else  
  #    []
  #  end  
  #end

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

  #
  # todo: make test
  #
  def str_to_a(arr)
    arr.kind_of?(String) ? [arr] : arr
  end

  def is_term_in_file(file, terms)
    has_words(str_to_a(terms), file_open(file, "r"))
  end
  
  #
  # to test
  #
  def words_in_file_content?(file, terms)
    terms.size == 0 || (File.file?(file) && is_term_in_file(file, terms))
  end

  def match(file, term)
    file.downcase.include?(term.start_with?("^") ? "/"+term.gsub("^","") : term)
  end

  def includes(file, terms)
    check_file(file)
    terms          = str_to_a(terms)

    content_tokens = get_words(terms)
    name_tokens    = get_non_words(terms)

    (content_tokens.size == 0 || words_in_file_content?(file, content_tokens)) && \
    (name_tokens.size == 0 || words_in_file_name?(file, name_tokens))
  end

  def colorize(text, terms)
    terms.each { |term| text = text.gsub(term, "#{term.green}") }
    text
  end

  def list_files(dir, terms)
    files = Dir.glob(dir)
    files = (@diff_only ? virtual_files : files + virtual_files)
              .select{|file| includes(file, terms) }
  end

  def display_matches(f, terms)
    File.open(f, "r").each_with_index do |item, index|
      print colorize("#{item}", terms) if  has_words(terms, item) 
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
        command = ask_simple("[q:quit text:code bloc search None:Go next] ").strip
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
    File.open(list_files(dir, %w(db schema.rb))[0], "r").each do |line|
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
    input = ask_simple(msg)
    return nil if input == "q" || input == ""
    a ? input.split(" ") : input
  end

  def ask_simple(msg)
    if @debug_mode
      @debug_mode
    else
      print "#{msg} "
      input = $stdin.gets.chomp.downcase
      abort if input == "q"
      input
    end  
  end

  def ask(msg, f, terms, a=false)
    input = ask_simple(msg)
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
    File.read(target_file).each_line
      .map {|line| line.strip }
      .select { |line| line.start_with?("def ")}
      .select { |func| !test_lines.include?(func) }
      .map {|func| func.gsub("def ", "" )}
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
        puts survey_test(f)
        return
      end  
    end

    #command = "bundle exec ruby -I test #{f} #{term} #{v}"
    command = "ruby -I test #{f} #{term} #{v}"
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

  def show_file_name(f, terms)
    file = colorize(File.basename(f), terms).split(" ")
    
    if file.size == 1
      puts "file: [#{file.first}] ?"
      return
    end

    file.push ""
    if file[1] != ""
      file[1] += ": "
    end
    p = `git --no-pager diff develop #{file[1]} #{file.first}`
    if p.empty?
      if File.exist?(f)
        File.open(f, "r").each do |line|
          puts line.green
        end
      else 
        p = `git show #{file[1]}:#{f}`
        puts p.magenta
      end
    else
      p.split("\n").each do |line|
        if line.start_with?("-")
          puts line.red
        elsif line.start_with?("+")
          puts line.green
        end
      end
    end  
    puts "file: [#{file[1].yellow}#{file.first}] ?"
  end

  def cache_file_path
    "/usr/local/etc/vimfind/cache"
  end

  def read_cache
    File.open(cache_file_path, "r").to_a
  end

  def cache_file_maximum
    10
  end

  def save_cache(new_file)
    cache_files = read_cache
    unless cache_files.include?(new_file)
      File.open(cache_file_path, "w") do |f|
        cache_files[0..cache_file_maximum].each do |old_file|
          f.puts old_file
        end
        f.puts new_file
      end
    end  
  end

  def execute_file(dir, files, f, index, terms, next_flag=false)
    file_path = colorize(f, terms)
    save_cache(file_path)
    puts "dir:  [#{colorize(File.dirname(f), terms)}]"
    show_file_name(f, terms)
    puts "[v: open with vim    ][q: quit                ]".cyan
    puts "[l: list methods     ][d: db schema search    ]"
    puts "[t: execute test     ][f: file sort           ]"
    puts "[o: open file        ][rm: remove this file]"
    puts "[ct: open corresponding test with vim]".yellow
    puts "[ce: execute corresponding test]".magenta
    puts "[vb: virtual branch reference]"
    puts "[r: rubocop search   ][b: blame               ]"
    puts "[! [command]: execute shell command]"
    puts 
    # TODO: free commadn execution should be added and 
    # bunch of commands above needs to be trimmed later.

    input = ask_simple("[p:prev n:next] Enter: ".cyan)

    f = f.split(" ").first

    if /^!.*/.match(input) 
      system "#{input[1..-1]}"
      puts
    end

    open_test(f)                  if input == "ct"
    open_test(f, true)            if input == "ce"
    system "rm #{f}"              if input == "rm"
    check_db(dir)                 if input == "d"
    system "vim #{format_into_mac(f)}" if (input == "y" || input == "v")
    open_file(f)                  if input == "o"
    refer(f)                      if input == "vb" 
    system "rubocop #{f}"         if input == "r"
    collect_funcs(f)              if input == "l"
    test(f, terms, "t")                if input == "t"
    test(f, terms, "t")           if input == "tt"
    open_https(f)                 if input == "u"
    system "git blame #{f}"       if input == "b"
    execute_files(sort(files, index), terms, dir) if input == "p"
    abort                         if input == "q"
    next_flag = true              if input == "n"
    Lib::FuncSort.sort(f)         if input == "f"
    if input == "s"
      search_all(ask_simple("[term:]").split(' '), dir, [], mvc_keyword) 
    end
    execute_file(dir, files, f, index, terms) unless next_flag
  end

  #
  # needs refactoring with this shitty boiler plate
  #
  def execute_files(files, terms, dir, i=0)
    key_terms = get_words(terms)
    if terms.size == 1
      puts terms
      files.select{|x| File.basename(x).start_with?(terms[0])}.each_with_index do |f, index|
        execute_file dir, files, f, index, terms
      end
      files.select{|x| !File.basename(x).start_with?(terms[0])}.each_with_index do |f, index|
        execute_file dir, files, f, index, terms
      end
    else
      files.each_with_index do |f, index|
        execute_file dir, files, f, index, terms
      end
    end  
  end

  def open_file(f)
    basename = format_into_mac(File.basename(f))
    system "open #{File.dirname(f)}/#{basename}"
  end

  def search_all(terms=nil, dir=nil)
    terms ||= @terms 
    dir   ||= directory
    execute_files list_files(dir, terms), terms, dir
  end

  private 

  def check_file(file)
    abort "\nFile [#{file}] does not exist.\n\n".red unless File.exist?(file)
  end

  def words_in_file_name?(file, non_terms)
    matches = non_terms.select { |term| match(file, term) }
    matches.size == non_terms.size
  end
end 
