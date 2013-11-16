#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

# This script uses an fxin_to_xxxpol.yml file to create an ASCII-grams of each
# all ROACH2 F Engine showing which xxx is connected to each input.
#
# The ouput is laid out as shown here:
#        f1
#    +------+------+-...    
# A1 |xxxxxx|xxxxxx|x...
# A2 |xxxxxx|xxxxxx|x...
# A3 |xxxxxx|xxxxxx|x...
# A4 |xxxxxx|xxxxxx|x...
#    +------+------+-...
# B1 |xxxxxx|xxxxxx|x...
# ...

grid_line = '-- +- f1 -+- f2 -+- f3 -+- f4 -+- f5 -+- f6 -+- f7 -+- f8 -+ --'

fin = ARGV[0] || 'fxin_to_plate.yml'

map = PaperCfg.load_file(fin)

puts "PAPER F Engine input to #{map.comp_to}:"
puts
puts grid_line

for chip in 'A'..'H'
  for chan in 1..4

    row = (1..8).map do |f|
      s = map["f#{f}#{chip}#{chan}"] || ''
      s.center(6)
    end

    printf "%s%d |%s| %s%d\n", chip, chan, row.join('|'), chip, chan
  end # chan

  puts grid_line

end # chip
