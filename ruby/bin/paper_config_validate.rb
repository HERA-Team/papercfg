#!/usr/bin/env ruby

# Script to validate hookup info

require 'papercfg'
include PaperCfg

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAPPING_FILE [...]"
  exit 1
end

ARGV.each do |f|
  puts "Loading mapping file #{f}"
  map = YAML.load_file(f)
  print_map_validity_for_filename(map, f)
  puts
end
