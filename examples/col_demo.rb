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
  $stderr.puts("\nUsage: col_demo <infile-name>\n\n")
  exit(1)
end

def dump_header_comments(file)
  if file.header_comments?
    puts("<Header>")
    file.header_comments.each_with_index { |line, i| puts("  #{i + 1}: #{line}") }
    puts("</Header>")
  end
end

def dump_footer_comments(file)
  if file.footer_comments?
    puts("<Footer>")
    file.footer_comments.each_with_index { |line, i| puts("  #{i + 1}: #{line}") }
    puts("</Footer>")
  end
end

def dump_content(file)
  puts("<Content>")
  file.entries.each_with_index do |entry, entry_no|

    puts("  <Entry ##{entry_no + 1}>")
    if entry.comment_before?
      entry.comment_before.each_with_index do |line, line_no|
        puts("    Entry ##{entry_no + 1} comment #{line_no + 1}: #{line}")
      end
      puts("    -----")
    end

    entry.columns.each_with_index do |col, col_no|
        puts("    Entry ##{entry_no + 1} col ##{col_no}: #{col}")
    end

    if entry.line_comment?
      puts("    Entry ##{entry_no + 1} line comment: #{entry.line_comment}")
    end
    puts("  </Entry ##{entry_no + 1}>")
    puts
  end
  puts("</Content>")
end

# main

usage unless ARGV.size == 1

filename = ARGV[0]
file = ColumnConfigFile.new
file.read(filename)

dump_header_comments(file)
puts if file.header_comments?
dump_content(file)
puts if file.footer_comments?
dump_footer_comments(file)
