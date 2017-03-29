#!/usr/bin/env ruby

option = $*[0]

case option
when "push"
  system "git push -f origin HEAD"
when "-h", "help"
  puts "reb ... rebase"
  puts "reb [push] ... force push"
else
  system "git fetch origin develop"
  sleep 3
  system "git pull --rebase origin develop"
end
