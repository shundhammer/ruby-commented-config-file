#!/usr/bin/env ruby
#
# Demo for the EtcFstab class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

SRC_PATH = File.expand_path("../../src", __FILE__)
$LOAD_PATH << SRC_PATH

require_relative "../src/etc_fstab"

def usage
  $stderr.puts("\nUsage: etc_fstab_demo <infile-name>\n\n")
  exit(1)
end

def dump_entry(entry)
  puts("<Entry>")
  puts("  device:        #{entry.device}")
  puts("  mount point:   #{entry.mount_point}")
  puts("  fs type:       #{entry.fs_type}")
  puts("  mount options: #{entry.mount_opts}")
  puts("  dump pass:     #{entry.dump_pass}")
  puts("  fsck pass:     #{entry.fsck_pass}")
  puts("</Entry>")
end

def report_mount_order_problems(fstab)
  if fstab.check_mount_order
    puts("Mount order okay.")
    return
  end

  puts
  puts("*** MOUNT ORDER ERROR! ***")
  problem_index = 0
  reported_problems = []
  loop do
    problem_index = fstab.next_mount_order_problem(problem_index)
    break if problem_index == -1
    entry = fstab.entries[problem_index]
    break if reported_problems.include?(entry)
    reported_problems << entry
    puts("Mount point #{entry.mount_point} is out of sequence!")
  end
  puts("Current sequence: #{fstab.mount_points}")
  fix_mount_order(fstab)
end

def fix_mount_order(fstab_old)
  puts("\nSuggested sequence (stripped header and footer comments):\n\n")
  fstab = fstab_old.dup
  fstab.fix_mount_order
  puts(fstab.format_entries.join("\n"))
end

usage unless ARGV.size == 1

filename = ARGV[0]
fstab = EtcFstab.new(filename)
fstab.entries.each { |e| dump_entry(e) }
report_mount_order_problems(fstab)
