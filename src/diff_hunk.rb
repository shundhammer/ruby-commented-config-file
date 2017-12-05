#!/usr/bin/env ruby
#
# Diff class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require "diff_range"

# Diff helper classes
#
class Diff
  # Helper class to collect information about one diff 'hunk'.
  #
  # One hunk is one set of changes with a number of consecutive lines removed
  # and a number of consecutive lines added instead.
  #
  class Hunk
    # @return [Array<String>]
    attr_accessor :lines_removed

    # @return [Array<String>]
    attr_accessor :lines_added

    # @return [Fixnum] start position of the removed lines
    #   without taking context lines into account
    attr_accessor :removed_start_pos

    # @return [Fixnum] start position of the added lines
    #   without taking context lines into account
    attr_accessor :added_start_pos

    # @return [Array<String>]
    attr_accessor :context_lines_before

    # @return [Array<String>]
    attr_accessor :context_lines_after

    def initialize
      @lines_removed = []
      @lines_added = []
      @removed_start_pos = 0
      @added_start_pos = 0
      @context_lines_before = []
      @context_lines_after = []
    end

    # Format this hunk like in the "diff -u" command.
    #
    # Notice that unlike Diff::format_hunks, this does not attempt to merge
    # consecutive hunks while formatting.
    #
    # @return [Array<String>]
    #
    def format
      result = format_lines
      result.unshift(format_header)
    end

    def to_s
      format.join("\n")
    end

    # Format the lines of this hunk. This does not include a header.
    # @return [Array<String>]
    #
    def format_lines
      result = []
      result.concat(prefix_lines(" ", @context_lines_before))
      result.concat(prefix_lines("-", @lines_removed))
      result.concat(prefix_lines("+", @lines_added))
      result.concat(prefix_lines(" ", @context_lines_after))
    end

    # Format the header for this hunk.
    # @return [String]
    #
    def format_header
      Hunk.format_header(removed_range, added_range)
    end

    # Format a hunk header.
    #
    # @param a [DiffRange]
    # @param b [DiffRange]
    #
    # @return [String]
    #
    # rubocop:disable Lint/UselessAssignment
    #
    def self.format_header(a, b)
      result = "@@ -"
      result += a.empty? ? "1" : "#{a.first + 1}"
      result += ",#{a.length}" if a.length != 1
      result += " +"
      result += b.empty? ? "1" : "#{b.first + 1}"
      result += ",#{b.length}" if b.length != 1
      result += " @@"
    end
    # rubocop:enable Lint/UselessAssignment

    def prefix_lines(prefix, lines)
      lines.map { |line| prefix + line }
    end

    # Get the range of the removed lines including context.
    # @return [DiffRange]
    #
    def removed_range
      first = @removed_start_pos - @context_lines_before.size
      last = @removed_start_pos + @lines_removed.size - 1
      last += @context_lines_after.size
      DiffRange.new(first, last)
    end

    # Get the range of the added lines including context.
    # @return [DiffRange]
    #
    def added_range
      first = @added_start_pos - @context_lines_before.size
      last = @added_start_pos + @lines_added.size - 1
      last += @context_lines_after.size
      DiffRange.new(first, last)
    end
  end
end
