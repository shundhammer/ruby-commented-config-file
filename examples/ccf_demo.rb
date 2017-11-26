#!/usr/bin/env ruby
#
# Demo for the CommentedConfigFile class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require_relative "../src/commented_config_file"

def usage
  $stderr.puts("\nUsage: ccf_demo <infile-name>\n\n")
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

    if entry.comment_before?
      puts
      entry.comment_before.each_with_index do |line, line_no|
        puts("  Entry ##{entry_no + 1} comment #{line_no + 1}: #{line}")
      end
    end

    puts("  Entry ##{entry_no + 1} content  : #{entry.content}")

    if entry.line_comment?
      puts("  Entry ##{entry_no + 1} line comment: #{entry.line_comment}")
    end
  end
  puts("</Content>")
end

# main

usage unless ARGV.size == 1

filename = ARGV[0]
file = CommentedConfigFile.new
file.read(filename)

dump_header_comments(file)
puts if file.header_comments?
dump_content(file)
puts if file.footer_comments?
dump_footer_comments(file)
