#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

# This script uses the plate_to_stapol.yml file to create ASCII-grams of each
# plate showing the station polarization that is fed to each connector.
#
# The interior of hut has six (used) plates:
#
#   +----+  +----+
#   | P2 |  | P1 |
#   +----+  +----+
#
#   +----+  +----+
#   | P4 |  | P1 |
#   +----+  +----+
#
#   +----+  +----+
#   | P6 |  | P5 |
#   +----+  +----+
#
# Each plate has 6 rows of 8 columns of connectors:
#
#       c8 c7 c6 c5 c4 c3 c2 c1
#     +------------------------+
#  r1 | o  o  o  o  o  o  o  o | r1
#  r2 | o  o  o  o  o  o  o  o | r2
#  r3 | o  o  o  o  o  o  o  o | r3
#  r4 | o  o  o  o  o  o  o  o | r4
#  r5 | o  o  o  o  o  o  o  o | r5
#  r6 | o  o  o  o  o  o  o  o | r6
#     +------------------------+
#       c8 c7 c6 c5 c4 c3 c2 c1

sep = ' | '

fin = ARGV[0] || 'plate_to_stapol.yml'

map = PaperCfg.load_file(fin)

for p in 1..6
  puts "PLATE #{p} #{map.comp_to} (as viewed from INSIDE the hut):"
  puts
  puts "      C8     C7     C6     C5     C4     C3     C2     C1"
  puts "   +------+------+------+------+------+------+------+------+"

  for r in 1..6
    stapols = (1..8).map do |c|
      s = map["p#{p}r#{r}c#{c}"] || ''
      # Strip leading 'r' (rxpol) or 's' (station) prefix letter
      s.sub!(/^[rs]/, '')
      '%-4s' % s
    end
    stapols.reverse!
    printf('R%d | ', r)
    printf('%s', stapols.join(sep))
    printf(' | R%d', r)
    puts
    puts "   +------+------+------+------+------+------+------+------+"
  end
  puts "      C8     C7     C6     C5     C4     C3     C2     C1"

  if p!= 6
    puts
    puts
    puts
  end
end
