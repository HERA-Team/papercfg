#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

# This script uses an sta_to_ant.yml file to create an ASCII-gram of the
# main grid showing which antennas are at which stations.

cell_text = '---'

fin = ARGV[0] || 'sta_to_ant.yml'
map = PaperCfg.load_file(fin)

# Pattern used to parse stations
pattern = PaperCfg::PATTERNS['sta']

puts "PAPER Antenna Numbers for Grid Station Positions:"
puts
puts "      0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15"
puts "  +-----------------------------------------------------------------+"

for r in 'ABCDEFGX'.split('')

  row_text = (0..15).map do |c|
    s = map["s#{r}#{c}"] || cell_text.dup
    # Strip prefix letter
    s.sub!(/^[a-z]/, '')
    s.rjust(3)
  end

  print "#{r} | "
  print row_text.join(' ')
  print " | #{r}"
  puts

  # Separate outlier row
  if r == 'G'
    puts "- +-----------------------------------------------------------------+ -"
  end
end
puts "  +-----------------------------------------------------------------+"
puts "      0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15"
