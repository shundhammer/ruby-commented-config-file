#!/usr/bin/env ruby
#
# CommentedConfigFile class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

# Utility class to read and write config files that might contain comments.
# This class tries to preserve any existing comments and keep them together
# with the content line immediately following them.
#
# This class supports the notion of a header comment block, a footer comment
# block, a comment block preceding any content line and a line comment on the
# content line itself.
#
# A comment preceding a content line is stored together with the content line,
# so moving around entries in the file will keep the comment with the content
# line it belongs to.
#
# The default comment marker is '#' like in most Linux config files, but it
# can be set with setCommentMarker().
#
# Example (line numbers added for easier reference):
#
#   001    # Header comment 1
#   002    # Header comment 2
#   003    # Header comment 3
#   004
#   005
#   006    # Header comment 4
#   007    # Header comment 5
#   008
#   009    # Content line 1 comment 1
#   010    # Content line 1 comment 2
#   011    content line 1
#   012    content line 2
#   013
#   014    content line 3
#   015
#   016    content line 4
#   017    content line 5 # Line comment 5
#   018    # Content line 6 comment 1
#   019
#   020    content line 6 # Line comment 6
#   021    content line 7
#   022
#   023    # Footer comment 1
#   024    # Footer comment 2
#   025
#   026    # Footer comment 3
#
#
# Empty lines or lines that have only whitespace belong to the next comment
# block: The footer comment consists of lines 022..026.
#
# The only exception is the header comment that stretches from the start of
# the file to the last empty line preceding a content line. This is what
# separates the header comment from the comment that belongs to the first
# content line. In this example, the header comment consists of lines
# 001..008.
#
# Content line 1 in line 011 has comments 009..010.
# Content line 2 in line 012 has no comment.
# Content line 3 in line 014 has comment 013 (an empty line).
# Content line 5 in line 017 has a line comment "# Line comment 5".
# Content line 6 in line 020 has comments 018..019 and a line comment.
#
# Applications using this class can largely just ignore all the comment stuff;
# the class will handle the comments automagically.
#
class CommentedConfigFile
  # @return [Array<Entry>] The config file entries.
  attr_accessor :entries

  # @return [String] The header comments, terminated with a newline.
  attr_accessor :header_comments

  # @return [String] The footer comments, terminated with a newline.
  attr_accessor :footer_comments

  # @return [String] The last filename content was read from.
  attr_reader :filename

  # @return [String] The comment marker; "#" by default.
  attr_accessor :comment_marker

  def initialize
    @comment_marker = "#"
    @header_comments = nil
    @footer_comments = nil
    @entries = []
    @filename = nil
  end

  def header_comments?
    !@header_comments.nil? && !@header_comments.empty?
  end

  def footer_comments?
    !@footer_comments.nil? && ! @footer_comments.empty?
  end

  def clear_entries
    @entries = []
  end

  def clear_all
    clear_entries
    @header_comments = nil
    @footer_comments = nil
  end

  # Check if a line is a comment line (not an empty line!).
  #
  # @param line [String] line to check
  #
  # @return [Boolean] true if comment, false otherwise
  #
  def comment_line?(line)
    line =~ /^\s*#{@comment_marker}.*/ ? true : false
  end

  # Create a new entry.
  # Derived classes might choose to override this.
  #
  # @return [CommentedConfigFile::Entry] new entry
  #
  def create_entry
    entry = Entry.new
    entry.parent = self
    entry
  end

  # Class representing one content line and the preceding comments.
  #
  # When subclassing this, don't forget to also overwrite
  # CommentedConfigFile::create_entry!
  #
  class Entry
    # @return [CommentedConfigFile] The parent CommentedConfigFile.
    attr_accessor :parent

    # @return [String] Content without any comment.
    attr_accessor :content

    # @return [String] Comment line(s) before the entry, terminated with a newline.
    attr_accessor :comment_before

    # @return [String] Comment on the same line as the entry without any newline.
    attr_accessor :line_comment

    def initialize
      @parent = nil
      @content = nil
      @comment_before = nil
      @line_comment = nil
    end

    def comment_before?
      !@comment_before.nil? && !@comment_before.empty?
    end

    def line_comment?
      !@line_comment.nil? && !@line_comment.empty?
    end

    # Parse a content line. This expects any line comment and the newline to be
    # stripped off already.
    #
    # Derived classes might choose to override this.
    #
    # @param line [String] content line without any line comment
    # @param line_no [Fixnum] line number for error reporting
    #
    # @return [Boolean] true if success, false if error
    #
    def parse(line, line_no = -1)
      @content = line
      true
    end

    # Format the content as a string.
    # Derived classes might choose to override this.
    # Do not add 'line_comment'; it is added by the caller.
    #
    # @return [String] formatted line without line comment.
    #
    def format
      content
    end

    alias_method :to_s, :format
  end
end
