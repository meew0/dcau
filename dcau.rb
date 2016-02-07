#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'pathname'
require 'open3'

PREFIXES = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']

# Convert one file to dca
def convert_one(path, output)
  start = Time.now
  Open3.popen2('dca', path) do |i, o, t|
    File.write(output, o.read)
  end

  # Statistics
  time_taken = Time.now - start
  input_size = File.size(path)
  output_size = File.size(output)
  [time_taken, input_size, output_size]
end

# Convert a size specified in bytes into something more pretty
def pretty_size(bytes)
  prefix_idx = 0
  until bytes < 1000.0
    bytes /= 1000.0
    prefix_idx += 1
  end

  bytes.round(3 - bytes.floor.to_s.length).to_s + PREFIXES[prefix_idx]
end

# Size reduction in percent
def reduction(insize, outsize)
  ((1 - outsize.to_f / insize.to_f) * 100).round(2)
end

options = OpenStruct.new
options.folder = '.'

parser = OptionParser.new do |opts|
  opts.on('-o', '--output FOLDER', 'Specifies the folder where the output should be saved.') do |folder|
    options.folder = folder
  end
end

parser.parse!

conversions = []

# Input files are now in ARGV
ARGV.each do |file|
  pn = Pathname.new(file)

  if pn.extname == '.dca'
    puts "Skipping #{file} - already a DCA file!"
    next
  end

  outpath = File.join(options.folder, pn.absolute? ? pn.basename('.*') : File.basename(file, '.*')) + '.dca'
  time, insize, outsize = convert_one(file, outpath)
  puts "Converted #{file} to DCA - took #{time.round(3)} seconds, input size #{pretty_size(insize)}, output size #{pretty_size(outsize)} (reduction #{reduction(insize, outsize)}%)"
  conversions << [time, insize, outsize]
end

puts '-' * 30
puts "Successfully converted #{conversions.length} files"
puts "Total time: #{conversions.map(&:first).reduce(0.0, &:+).round(3)} seconds"
puts "Average file size reduction: #{conversions.map { |c| reduction(c[1], c[2]) }.reduce(0.0, &:+) / conversions.length}%"
