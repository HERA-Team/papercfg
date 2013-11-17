#!/usr/bin/env ruby

require 'rubygems'
require 'date'
require 'ostruct'
require 'optparse'
require 'coord'
require 'papercfg'
require 'pgplot/plotter'
include Pgplot

opts = OpenStruct.new
opts.device = ENV['PGPLOT_DEV'] || '/xs'

ARGV.options do |op|
  op.program_name = File.basename($0)

  op.banner = "Usage: #{op.program_name} [OPTIONS] [STA_TO_POS]"
  op.separator('')
  op.separator('Plot PAPER antenna positions from STA_TO_POS file.')
  op.separator('STA_TO_POS defaults to sta_to_pos.yml in the current directory.')
  op.separator('')
  op.separator('Options:')
  op.on('-d', '--device=DEVICE', "PGPLOT device [#{opts.device}]") do |o|
    opts.device = o
  end
  op.on_tail('-h','--help','Show this message') do
    puts op.help
    exit
  end
  op.parse! 
end

fin = ARGV[0] || 'sta_to_pos.yml'
map = PaperCfg.load_file(fin)
fin_git_hash = Digest.git_hash(fin).to_s[0,7]

abspos = map.to_hash
abspos.delete 'metadata'
# Create relpos by subtracting refpos from each element of abspos
refpos = abspos['sZ0']
relpos = {}
abspos.each {|s,p| relpos[s] = p.sub(refpos) if p}

enu = relpos.values.transpose

erange = enu[0].minmax
nrange = enu[1].minmax
noffset = (nrange[1]-nrange[0])/100
nrange[0] -= 10
nrange[1] += 10
erange[0] -= 10
erange[1] += 10

# Initialize plot device
Plotter.new(:device => opts.device)
plot(erange, nrange,
     :title => 'PAPER Antenna Positions',
     :title2 => "from #{File.basename fin} with git hash #{fin_git_hash}",
     :line=>:none,
     :just => true,
     :xlabel => 'West - East',
     :ylabel => 'South - North'
    )

line_style = pgqls
pgsls(Line::DASHED)
pgsci(Color::WHITE)
pgline([-1e6,1e6], [0, 0])
pgline([0, 0], [-1e6,1e6])
pgsls(line_style)

pgsci(Color::ORANGE)

def plot_station(station, pos)
  station = station.sub(/^s/, '')
  e, n, u = pos

  color = Color::ORANGE
  #color = case i
  #        when 0...6; Color::ORANGE
  #        when 6...15; Color::BLUE
  #        when 15...23; Color::YELLOW
  #        else Color::RED
  #        end
  #pgsci(color)

  pgpt1(e, n, Marker::SQUARE)
  #pgptxt(e, n, 0.5, 0.5, station)

  ## Draw box around station name
  #ee, nn = pgqtxt(e, n, 0.5, 0.5, station)
  ##nn.map! {|y| y+noffset}
  #ee << ee[0]
  #nn << nn[0]
  #plot(ee, nn,
  #     :overlay => true,
  #     :line_color => color
  #    )
end

for r in 'ABCDEFGX'.split('')
  for c in 0..15
    s = "s#{r}#{c}"
    pos = relpos[s]
    if pos
      plot_station(s, pos)
    else
      puts "warning: no position for station #{s}"
    end
  end
end
