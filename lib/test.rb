require "/usr/local/lib/vf/util.rb"

class Test
  $recollection_dir = "/usr/local/etc/ddff"

  def self.recollect_last_test(test_file)
    system "mkdir -p #{$recollection_dir}"
    system "echo #{test_file} > #{$recollection_dir}/recollection" 
  end

  def self.testare(files, kw = "")
    files = Util.filter_tail(files, "_test.rb")
    if files.size == 0
      puts "\n0 files found\n".red
      files = $files_all 
    end  

    if files.size == 1
      command = "bundle exec ruby -I test #{files[0]} --verbose"
      puts "command: #{command}".green
      recollect_last_test(files[0])
      system command
      abort
    end

    puts
    files.each_with_index do |tfile, i|
      puts "#{i}: #{Util.gsubs(tfile, kw)}"
    end
    i = Util.index
    return if Util.extra_option_2(i)
    if i == ""
      p = `cat #{$recollection_dir}/recollection`
      testare [p.to_s.strip]
    elsif i == "all"
      files.each do |file|
        command = "bundle exec ruby -I test #{file} --verbose"
        puts "command: #{command}".green
        system command
      end
    elsif !/[^0-9]/.match(i).nil?  
      testare(files.select {|file| Util.has?(file, i)}, i)
    else  
      file = files[i.to_i]
      command = "bundle exec ruby -I test #{file} --verbose"
      puts "command: #{command}".green
      recollect_last_test(file)
      system command
    end  
  end
end
