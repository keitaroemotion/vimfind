class Sync

  def self.get_large_files(files, branch, kw)
    if !kw
      puts "git diff --name-only #{branch}".green
      files = `git diff --name-only #{branch}`.split("\n").map do |file|
        file.strip 
      end
      kw = ""
    end  
    files = files.select {|x| x.include?(kw)}
    files
  end

  def self.find_branch(files, branches = [], kw = nil)
    if kw
      branches = branches.select{|x| x.include?(kw)}
    elsif branches.nil? || branches.size == 0
      branches = `git branch`.split("\n")
    end  
    branches.each_with_index do |br, i|
      puts "#{i.to_s.green} #{br}"
    end
    print "[from which?] "
    i = $stdin.gets.chomp
    if i.nil?
      return find_branch files, branches
    elsif /[^0-9]/.match(i)
      return find_branch(files, branches, i)
    else
      return branches[i.to_i]
    end
  end

  def self.transfer(targets, branch)
    targets.each do |file|
      puts "[#{file}]".cyan
    end

    print "okay? [y/n]: "
    option = $stdin.gets.chomp.downcase
    if option == "y"
      targets.each do |file|
        puts   "git co #{branch.strip} #{file.strip}".green
        system "git co #{branch} #{file}"
      end
    end
  end

  def self.sync(files, kw = nil, branch = nil)
    branch = find_branch(files).gsub("*", "").strip if branch.nil?
    files = get_large_files(files, branch, kw)
    files.each_with_index do |file, i|
     puts "#{i.to_s.magenta} #{file}"
    end
    print "Select files[ex. 0 2 3 4/all]: "
    i = $stdin.gets.chomp
    if i == "q"
      return
    elsif i.nil?
      return sync files, i, branch
    elsif i == "all"
     transfer(files, branch)
    elsif !/[^0-9\ ]/.match(i).nil?
      return sync(files, i, branch)
    else
     targets = i.split(" ").map{|x| files[x.to_i]}
     transfer(targets, branch)
    end
  end
end

