#!/usr/bin/env ruby

# Script to chain multiple mappings into one end-to-end mapping.

require 'papercfg'
include PaperCfg

if ARGV.length < 2
  puts "usage: #{File.basename($0)} MAP_FILE1 MAP_FILE2 [...]"
  exit 1
end

maps = ARGV.map do |f|
  #puts "Loading mapping file #{f}"
  PaperCfg.load_file(f)
end

# This is PaperCfg's "smart sort"
keys = sort(maps[0].keys)

# Find max key length
max_key = keys.max_by {|k| k.length}
width = max_key.length

keys.each do |key|
  val = maps.inject(key) {|k,m| m[k]}
  printf("%-*s : %s\n", width, key, val)
end
