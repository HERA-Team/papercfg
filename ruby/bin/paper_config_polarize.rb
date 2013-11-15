#!/usr/bin/env ruby

# Polarize a mapping file by duplicating each key/value pair of the input map
# twice; once with an 'X' suffix on key and value and once with a 'Y' suffix on
# key and value.
#
# Currently it does not prevent polarizing an already polarized file.

require 'rubygems'
require 'papercfg'

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAP_FILE"
  exit 1
end

map = PaperCfg.load_file(ARGV[0])


puts map.polarize.to_yaml
