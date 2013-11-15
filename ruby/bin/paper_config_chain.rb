#!/usr/bin/env ruby

# Script to chain multiple mappings into one end-to-end mapping.
#
# Passing a single mapping file will output a sorted version of it (with all
# comments removed).

require 'rubygems'
require 'papercfg'

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAP_FILE1 [MAP_FILE2 [...]]"
  exit 1
end

maps = ARGV.map do |f|
  #puts "Loading mapping file #{f}"
  PaperCfg.load_file(f)
end

map0 = maps.shift
puts map0.chain(*maps).to_yaml
