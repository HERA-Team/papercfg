#!/usr/bin/env ruby

# Script to validate hookup info

require 'rubygems'
require 'papercfg'
include PaperCfg

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAPPING_FILE [...]"
  exit 1
end

ARGV.each do |f|
  map = PaperCfg.load_file(f)
  map.print_validity
end
