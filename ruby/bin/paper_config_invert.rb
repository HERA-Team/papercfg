#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

# Script to invert a mapping file

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAPPING_FILE"
  exit 1
end

map = PaperCfg.load_file(ARGV[0])
puts <<EOF
# PAPER configuration mapping.
# Created by #{File.basename($0)}
# from file #{File.basename(ARGV[0])} at #{Time.now}.
EOF

puts map.invert.to_yaml
