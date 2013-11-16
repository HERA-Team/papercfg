#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

# This script uses an fxin_to_xxxpol.yml file to create ASCII-grams of each
# ROACH2 F Engine showing the xxxpol that is fed into each input connector.
#
#
# The input connectors on the ROACH2 or arranged as shown here:
#
#
#       E   F   G   H       A    B   C   D
#  4    o   o   o   o  4    o    o   o   o  4
#      /   /   /   /       /    /   /   /
#  2  o   o   o   o    2  o    o   o   o    2
#      \   \   \   \       \    \   \   \
#  3    o   o   o   o  3    o    o   o   o  3
#      /   /   /   /       /    /   /   /
#  1  o   o   o   o    1  o    o   o   o    1
#     E   F   G   H       A    B   C   D

sep = '    '
mid = '     '

fin = ARGV[0] || 'fxin_to_plate.yml'

map = PaperCfg.load_file(fin)

for f in 1..8
  puts "PAPER F Engine #{f} (pf#{f}) Faceplate:"
  puts

  print(' '*4)
  print(['E','F','G','H'].join(' '*9))
  print(' '*10)
  print(['A','B','C','D'].join(' '*9))
  puts

  print((['---------']*4).join(' '))
  print '  '
  print((['---------']*4).join(' '))
  puts

  for r in [4, 2, 3, 1]
    left = ('E'..'H').map do |c|
      s = map["f#{f}#{c}#{r}"] || ''
      s.center(6)
    end
    right = ('A'..'D').map do |c|
      s = map["f#{f}#{c}#{r}"] || ''
      s.center(6)
    end

    print '   ' if r > 2 # Row leader for "indented" rows
    printf('%s%s%s', left.join(sep), mid, right.join(sep))
    puts
  end

  print((['---------']*4).join(' '))
  print '  '
  print((['---------']*4).join(' '))
  puts

  print(' '*4)
  print(['E','F','G','H'].join(' '*9))
  print(' '*10)
  print(['A','B','C','D'].join(' '*9))
  puts

  if f != 8
    puts
    puts
  end
end
