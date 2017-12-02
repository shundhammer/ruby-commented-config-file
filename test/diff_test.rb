#!/usr/bin/rspec
#
# Unit test for CommentedConfigFile
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

# Get a grip on insane restrictions imposed by rubocop:
#
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/BlockLength
# rubocop:disable Style/WordArray

require_relative "support/spec_helper"
require "diff"
require "pp"

def read_file(filename)
  lines = []
  open(filename).each { |line| lines << line.chomp }
  lines
end

def read_files(prefix, pattern)
  path = "data/diff/"
  filenames = Dir.glob(path + prefix + pattern).sort
  filenames.each_with_object({}) do |filename, hash|
    name = filename.gsub(path + prefix, "")
    hash[name] = read_file(filename)
  end
end

describe Diff do
  context "Simple diffs without context" do
    let(:input01) { ["aaa", "bbb", "ccc", "ddd"] }
    let(:input02) { ["aaa",        "ccc", "ddd"] }
    let(:aaa) { ["aaa"] }
    let(:bbb) { ["aaa", "bbb"] }
    let(:ccc) { ["aaa", "bbb", "ccc"] }

    describe "#diff" do
      it "detects one added line" do
        expect(Diff.diff(input02, input01, 0)).to eq ["@@ -1,0 +2 @@", "+bbb"]
      end

      it "detects one deleted line" do
        expect(Diff.diff(input01, input02, 0)).to eq ["@@ -2 +1,0 @@", "-bbb"]
      end

      it "does nothing on identical input" do
        expect(Diff.diff(aaa, aaa, 0)).to eq []
        expect(Diff.diff(input01, input01, 0)).to eq []
      end

      it "can handle empty input on both sides" do
        expect(Diff.diff([], [], 0)).to eq []
      end

      it "can handle empty input in lines_a" do
        expect(Diff.diff([], aaa, 0)).to eq ["@@ -1,0 +1 @@", "+aaa"]
      end

      it "can handle empty input in lines_b" do
        expect(Diff.diff(aaa, [], 0)).to eq ["@@ -1 +1,0 @@", "-aaa"]
      end

      it "detects multiple added lines" do
        expect(Diff.diff(aaa, ccc, 0)).to eq ["@@ -1,0 +2,2 @@", "+bbb", "+ccc"]
      end
    end
  end

  context "Advanced diffs with context" do
    describe "#diff" do
      input = read_files("input", "??")
      expected = read_files("expected_", "??_??")
      expected.each do |_key, value|
        # kill any lines starting with +++ or --- that "diff -u" left behind
        value.delete_if { |line| line =~ /^(\+\+\+|---)/ }
      end

      let(:context_lines) { 3 }

      expected.each do |key, expected_lines|
        name_a, name_b = key.split("_")

        it "correctly diffs input#{name_a} against input#{name_b}" do
          lines_a = input[name_a]
          lines_b = input[name_b]
          expect(Diff.diff(lines_a, lines_b, context_lines)).to eq expected_lines
        end
      end
    end
  end
end
