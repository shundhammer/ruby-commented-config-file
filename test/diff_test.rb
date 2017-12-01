#!/usr/bin/rspec
#
# Unit test for CommentedConfigFile
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require_relative "support/spec_helper"
require "diff"

# rubocop:disable Lint/AmbiguousRegexpLiteral
# rubocop:disable Metrics/BlockLength

describe Diff do
  context "Simple diffs without context" do
    let(:input01) { [ "aaa", "bbb", "ccc", "ddd" ] }
    let(:input02) { [ "aaa",        "ccc", "ddd" ] }
    let(:aaa) { [ "aaa" ] }
    let(:bbb) { [ "aaa", "bbb" ] }
    let(:ccc) { [ "aaa", "bbb", "ccc" ] }

    describe "#diff" do
      it "detects one added line" do
        expect(Diff::diff(input02, input01, 0)).to eq ["@@ -1,0 +2 @@", "+bbb"]
      end

      it "detects one deleted line" do
        expect(Diff::diff(input01, input02, 0)).to eq ["@@ -2 +1,0 @@", "-bbb"]
      end

      it "does nothing on identical input" do
        expect(Diff::diff(aaa, aaa, 0)).to eq []
        expect(Diff::diff(input01, input01, 0)).to eq []
      end

      it "can handle empty input on both sides" do
        expect(Diff::diff([], [], 0)).to eq []
      end

      it "can handle empty input in lines_a" do
        expect(Diff::diff([], aaa, 0)).to eq ["@@ -1,0 +1 @@", "+aaa"]
      end

      it "can handle empty input in lines_b" do
        expect(Diff::diff(aaa, [], 0)).to eq ["@@ -1 +1,0 @@", "-aaa"]
      end

      it "detects multiple added lines" do
        expect(Diff::diff(aaa, ccc, 0)).to eq ["@@ -1,0 +2,2 @@", "+bbb", "+ccc"]
      end
    end
  end
end
