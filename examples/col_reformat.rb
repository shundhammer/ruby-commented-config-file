#!/usr/bin/env ruby
#
# Demo for the CommentedConfigFile class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

SRC_PATH = File.expand_path("../../src", __FILE__)
$LOAD_PATH << SRC_PATH 

require_relative "../src/column_config_file"

def usage
  $stderr.puts("\nUsage: col_reformat <infile-name>\n\n")
  exit(1)
end


# main

usage unless ARGV.size == 1

filename = ARGV[0]
file = ColumnConfigFile.new

# file.input_delimiter = ":" # for /etc/passwd
file.read(filename)

# Reasonable values for /etc/fstab

# file.max_column_widths = [45, 25, 7, 30, 1, 1]
# file.fallback_max_column_width = 100
# file.pad_columns = false
# file.output_delimiter = " "

file.format_lines.each { |line| puts line }
