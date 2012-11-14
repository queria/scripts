#!/usr/bin/env ruby

lines = {}

ARGF.each do |line|
  line.chomp! # usefull for me but ... ?
  lines[ line ] = ( lines[line] || 0 ) + 1
end

lines.sort_by{ |x| x[1] }.reverse.each do |line,count|
  puts "#{count}\t#{line}"
end

