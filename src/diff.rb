#!/usr/bin/env ruby
#
# Diff class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

# Get a grip on insane restrictions imposed by rubocop:
#
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
# rubocop:disable Style/NegatedIf
# rubocop:disable Style/Next

require "diff_range"
require "diff_hunk"

# Class to diff string vectors against each other. This is very much like the
# Linux/Unix "diff -u" command.
#
class Diff
  DEFAULT_CONTEXT_LINES = 3

  # @return [Array<Diff::Hunk>] The diff hunks after the diff was performed.
  attr_reader :hunks

  # Constructor: Initialize everything and perform the diff.
  # Use format_hunks to get the result or iterate over the hunks.
  #
  # It is typically easier to use Diff.diff instead.
  #
  # @param lines_a [Array<String>]
  # @param lines_a [Array<String>]
  # @param context_lines [Fixnum] number of context lines in the result
  #
  def initialize(lines_a, lines_b, context_lines = DEFAULT_CONTEXT_LINES)
    @lines_a = lines_a.dup || []
    @lines_b = lines_b.dup || []
    @context_lines = context_lines
    @hunks = []

    diff(DiffRange.create(@lines_a), DiffRange.create(@lines_b))
    fix_hunk_overlap
  end

  # Diff two sets of lines.
  #
  # @param lines_a [Array<String>]
  # @param lines_b [Array<String>]
  # @param context_lines [Fixnum] number of context lines in the result
  #
  # @result [Array<String>]
  #
  def self.diff(lines_a, lines_b, context_lines = DEFAULT_CONTEXT_LINES)
    d = Diff.new(lines_a, lines_b, context_lines)
    d.format_hunks
  end

  # Format a patch header like expected by the Linux patch(1) command:
  #
  #   --- filename_old
  #   +++ filename_new
  #
  # This does not make the diff output prettier, but it can be fed directly
  # to the 'patch' command. If there is no such header, the 'patch' command
  # will complain "input contains only garbage".
  #
  # @param filename_old [String]
  # @param filename_new [String]
  #
  # @return [Array<String>]
  #
  def self.format_patch_header(filename_old, filename_new)
    ["--- #{filename_old}", "+++ #{filename_new}"]
  end

  # Format the hunks. This also merges overlapping hunks (but just for the
  # output).
  #
  # @return [Array<String>]
  #
  def format_hunks
    result = []
    merged_lines = []
    merged_range_a = DiffRange.new
    merged_range_b = DiffRange.new

    @hunks.each_with_index do |hunk, i|
      merging = false

      if i < @hunks.size - 1
        current_last = hunk.removed_range.last
        next_first = @hunks[i + 1].removed_range.first

        merging = true if current_last + 1 >= next_first
      end

      if merging || !merged_lines.empty?
        range_a = hunk.removed_range.dup
        range_b = hunk.added_range.dup

        if merged_lines.empty?
          merged_range_a.first = range_a.first
          merged_range_b.first = range_b.first
        end

        merged_range_a.last = range_a.last
        merged_range_b.last = range_b.last

        merged_lines.concat(hunk.format_lines)
      end

      if !merging
        if !merged_lines.empty?
          # Flush pending merged lines
          result << Hunk.format_header(merged_range_a, merged_range_b)
          result.concat(merged_lines)
          merged_lines = []
        else
          result.concat(hunk.format)
        end
      end
    end

    result
  end

  protected

  # Diff lines_a against lines_b between ranges a and b and store the result in
  # the internal hunks.
  #
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def diff(a, b)
    skip_common_start(a, b)
    skip_common_end(a, b)

    return if a.empty? && b.empty?

    (pos_a, pos_b, len) = find_common_subsequence(a, b)

    if len > 0
      # Cut into two parts and recurse
      diff(DiffRange.new(a.first, pos_a - 1), DiffRange.new(b.first, pos_b - 1))
      diff(DiffRange.new(pos_a + len, a.last), DiffRange.new(pos_b + len, b.last))
    else
      add_hunk(a, b)
    end
  end

  # Skip common lines at the start between ranges a and b.
  #
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def skip_common_start(a, b)
    while !a.empty? && !b.empty?
      return if @lines_a[a.first] != @lines_b[b.first]
      a.skip_first
      b.skip_first
    end
  end

  # Skip common lines at the end between ranges a and b.
  #
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def skip_common_end(a, b)
    while !a.empty? && !b.empty?
      return if @lines_a[a.last] != @lines_b[b.last]
      a.skip_last
      b.skip_last
    end
  end

  # Find a common subsequence between ranges a and b.
  #
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  # @return [Array<FixNum>] pos_a, pos_b, len of the subsequence
  #
  def find_common_subsequence(a, b)
    best_pos_a = -1
    best_pos_b = -1
    best_len = 0

    a.each do |pos_a|
      b.each do |pos_b|
        next unless @lines_a[pos_a] == @lines_b[pos_b]

        # Found a sequence start
        i = pos_a + 1
        j = pos_b + 1

        while a.cover?(i) && b.cover?(j) && @lines_a[i] == @lines_b[j]
          i += 1
          j += 1
        end

        len = i - pos_a
        next if len <= best_len # This sequence is no better than the old one

        # Found a new best sequence, so let's store it
        best_len = len
        best_pos_a = pos_a
        best_pos_b = pos_b
      end
    end

    [best_pos_a, best_pos_b, best_len]
  end

  # Add a hunk for ranges a and b.
  #
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def add_hunk(a, b)
    hunk = Hunk.new
    hunk.lines_removed = @lines_a.slice(a.first, a.length)
    hunk.lines_added = @lines_b.slice(b.first, b.length)
    hunk.removed_start_pos = @lines_a.empty? ? -1 : a.first
    hunk.added_start_pos   = @lines_b.empty? ? -1 : b.first
    add_context(hunk, a, b)
    @hunks << hunk
  end

  # Add hunk context for a hunk between ranges a and b.
  #
  # @param hunk [Diff::Hunk]
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def add_context(hunk, a, b)
    add_context_before(hunk, a, b)
    add_context_after(hunk, a, b)
  end

  # Add hunk context before the hunk for a hunk between ranges a and b.
  #
  # @param hunk [Diff::Hunk]
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def add_context_before(hunk, a, _b)
    return unless a.first > 0
    context = DiffRange.new
    context.first = [0, a.first - @context_lines].max
    context.last = [0, a.first - 1].max
    hunk.context_lines_before = @lines_a.slice(context.first, context.length)
  end

  # Add hunk context after the hunk for a hunk between ranges a and b.
  #
  # @param hunk [Diff::Hunk]
  # @param a [DiffRange]
  # @param b [DiffRange]
  #
  def add_context_after(hunk, a, _b)
    return unless a.last < @lines_a.size - 1
    context = DiffRange.new
    context.first = [@lines_a.size - 1, a.last + 1].min
    context.last  = [@lines_a.size - 1, a.last + @context_lines].min
    hunk.context_lines_after = @lines_a.slice(context.first, context.length)
  end

  # Make sure hunks don't overlap because of context lines:
  # Reduce their contexts if necessary.
  #
  def fix_hunk_overlap
    @hunks.each_with_index do |hunk, i|
      next if i < 1
      prev_hunk = @hunks[i - 1]
      prev_last = prev_hunk.removed_range.last
      current_first = hunk.removed_range.first
      overlap = prev_last - current_first + 1
      remove_hunk_overlap(prev_hunk.context_lines_after,
                          hunk.context_lines_before, overlap)
    end
  end

  # Remove hunk context overlap for context lines.
  #
  # @param prev_context [Array<String>]
  # @param current_context [Array<String>]
  # @param overlap [Fixnum] number of overlapping lines
  #
  def remove_hunk_overlap(prev_context, current_context, overlap)
    while overlap > 0
      if !prev_context.empty?
        # Remove the last line from the context of the previous hunk
        prev_context.pop
        overlap -= 1
      end

      if overlap > 0 && !current_context.empty?
        # Remove the first line from the context of the current hunk
        current_context.shift
        overlap -= 1
      end
    end
  end
end
