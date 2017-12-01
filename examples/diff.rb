#!/usr/bin/env ruby
#
# Demo for the Diff class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

SRC_PATH = File.expand_path("../../src", __FILE__)
$LOAD_PATH << SRC_PATH

require_relative "../src/diff"

def usage
  $stderr.puts("\nUsage: diff.rb <filename1> <filename2>\n\n")
  exit(1)
end

def read(filename)
  lines = []
  open(filename).each { |line| lines << line.chomp }
  lines
end

# main

usage unless ARGV.size == 2

filename_a = ARGV[0]
filename_b = ARGV[1]

lines_a = read(filename_a)
lines_b = read(filename_b)

diff_lines = Diff::diff(lines_a, lines_b)

puts diff_lines.join("\n")
