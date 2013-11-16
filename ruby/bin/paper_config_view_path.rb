#!/usr/bin/env ruby

# Script to print map path through multiple mappings.

require 'rubygems'
require 'papercfg'

if ARGV.empty?
  puts "usage: #{File.basename($0)} MAP_FILE1 [MAP_FILE2 [...]]"
  exit 1
end

maps = ARGV.map do |f|
  PaperCfg.load_file(f)
end

map0  = maps.shift

paths = map0.path(*maps)

maxpath_key = paths.keys.max_by {|k| paths[k].length}
maxpath_len = paths[maxpath_key].length

widths = (0...maxpath_len).map do |depth|
  values_at_depth = paths.values.map {|va| va[depth]}
  values_at_depth.compact
  max_value_at_depth = values_at_depth.max_by {|v| v.length}
  max_value_at_depth.length
end

keys = PaperCfg.sort(paths.keys)

keys.each do |k|
  path = paths[k]
  path.length.times {|i| path[i] = '%-*s' % [widths[i], path[i]]}
  puts path.join(' -> ')
end
