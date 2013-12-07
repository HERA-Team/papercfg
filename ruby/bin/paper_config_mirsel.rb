#!/usr/bin/env ruby

require 'rubygems'
require 'papercfg'

def ants_in_row(map, row)
  ants=[]
  if row
    16.times do |col|
      ants << map["s#{row}#{col}"][1..-1].to_i + 1
    end
  end
  ants
end

def ants_in_col(map, col)
  ants=[]
  if col
    'ABCDEFGX'.each_char do |row|
      ants << map["s#{row}#{col}"][1..-1].to_i + 1
    end
  end
  ants
end

map = PaperCfg.load_file('sta_to_ant.yml')

# Do rows
'ABCDEFGX'.each_char do |row|
  puts "row#{row.downcase}=#{ants_in_row(map,row).join(',')}"
end

# Do cols
16.times do |col|
  ants = ants_in_col(map, col)
  ants.pop # Remove X row
  puts "col#{col}=#{ants.join(',')}"
end

__END__

sel = ARGV.pop || 'A'
sel = sel.upcase

row, col = case sel
           when /^[0-9]/
             [nil, sel.to_i]
           else
             [sel[0,1].upcase, nil]
           end

ants = row ? ants_in_row(map, row) : ants_in_col(map, col)

print 'select='
print "ant(#{ants.join(',')})(#{ants.join(',')})"
unless ARGV.empty?
  print ","
  print ARGV.join(',')
end
puts
