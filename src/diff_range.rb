#!/usr/bin/env ruby
#
# Diff class
#
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

# rubocop:disable Style/Alias

# Helper class defining an interval to operate in: From line no. 'first'
# (starting with 0) including to line no. 'last'.
#
class DiffRange
  include Enumerable

  # @return [Fixnum] The start of the range.
  attr_accessor :first

  # @return [Fixnum] The end of the range.
  attr_accessor :last

  def initialize(first = 0, last = -1)
    @first = first
    @last = last
  end

  # Create a range from an object that has a size.
  # This is most useful for arrays or similar types.
  #
  def self.create(obj)
    new(0, obj.size - 1)
  end

  def size
    @last - @first + 1
  end

  alias_method :length, :size

  def empty?
    @first > @last
  end

  def valid?
    @first <= @last + 1
  end

  def skip_first
    @first += 1 if @first <= @last
  end

  def skip_last
    @last -= 1 if @first <= @last
  end

  # Check if a position is in the range.
  # @return [Boolean]
  #
  def cover?(x)
    x >= @first && x <= @last
  end

  def to_s
    "(#{@first}..#{@last})"
  end

  alias_method :in_range?, :cover?

  # Provide iterator infrastructure
  def each(&block)
    (@first..@last).each(&block)
  end

  def to_range
    (@first..@last)
  end
end
