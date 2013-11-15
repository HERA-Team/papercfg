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

fin = ARGV[0]

map = PaperCfg.load_file(fin)

puts <<EOF
# Derived PAPER configuration mapping created by #{File.basename($0)}
# Derived from: #{Digest.git_hash(fin).to_s[0,7]} #{File.basename(fin)}
EOF

puts map.polarize.to_yaml
