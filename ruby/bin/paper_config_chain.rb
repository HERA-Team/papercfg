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
  PaperCfg.load_file(f)
end

argv0 = ARGV.shift
map0  = maps.shift

puts <<EOF
# Derived PAPER configuration mapping created by #{File.basename($0)}
# Derived from: #{Digest.git_hash(argv0).to_s[0,7]} #{File.basename(argv0)}
EOF

ARGV.each do |f|
  puts <<EOF
#               #{Digest.git_hash(f).to_s[0,7]} #{File.basename(f)}
EOF
end

puts map0.chain(*maps).to_yaml
