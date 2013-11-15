#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

# Script to invert a mapping file

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAP_FILE"
  exit 1
end

fin = ARGV[0]

map = PaperCfg.load_file(fin)

puts <<EOF
# Derived PAPER configuration mapping created by #{File.basename($0)}
# Derived from: #{Digest.git_hash(fin).to_s[0,7]} #{File.basename(fin)}
EOF

puts map.invert.to_yaml
