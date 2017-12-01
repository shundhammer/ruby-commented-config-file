#!/usr/bin/rspec
#
# Unit test for CommentedConfigFile
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require_relative "support/spec_helper"
require "diff_range"

# rubocop:disable Lint/AmbiguousRegexpLiteral
# rubocop:disable Metrics/BlockLength

describe DiffRange do
  describe "#new" do
    context "created empty" do
      subject { DiffRange.new }

      it "has the correct first and last" do
        expect(subject.first).to be == 0
        expect(subject.last).to be == -1
      end

      it "has the correct size" do
        expect(subject.size).to be == 0
      end

      it "is empty" do
        expect(subject.empty?).to eq true
      end

      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "created with size 1" do
      subject { DiffRange.new(0, 0) }

      it "has the correct size" do
        expect(subject.size).to be == 1
      end

      it "is not empty" do
        expect(subject.empty?).to eq false
      end

      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end
  end

  describe "#create" do
    context "created from an array" do
      let(:array) { [ "aaa", "bbb", "ccc", "ddd" ] }
      subject { DiffRange.create(array) }

      it "has the correct first and last" do
        expect(subject.first).to be == 0
        expect(subject.last).to be == 3
      end

      it "has the correct size" do
        expect(subject.size).to be == 4
      end

      it "is not empty" do
        expect(subject.empty?).to eq false
      end

      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "created from an empty array" do
      subject { DiffRange.create([]) }

      it "has the correct first and last" do
        expect(subject.first).to be == 0
        expect(subject.last).to be == -1
      end

      it "has the correct size" do
        expect(subject.size).to be == 0
      end

      it "is empty" do
        expect(subject.empty?).to eq true
      end

      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end
  end

  describe "#skip_first" do
    let(:array) { [ "aaa", "bbb", "ccc", "ddd" ] }
    subject { DiffRange.create(array) }

    it "correctly skips the first position" do
      subject.skip_first
      expect(subject.first).to be == 1
      expect(subject.last).to be == 3
      expect(subject.size).to be == 3
    end

    it "correctly skips the first 3 positions" do
      3.times { subject.skip_first }
      expect(subject.first).to be == 3
      expect(subject.last).to be == 3
      expect(subject.size).to be == 1
    end

    it "does not skip beyond the last" do
      10.times { subject.skip_first }
      expect(subject.first).to be == 4
      expect(subject.last).to be == 3
      expect(subject.size).to be == 0
      expect(subject.empty?).to eq true
    end
  end

  describe "#skip_last" do
    let(:array) { [ "aaa", "bbb", "ccc", "ddd" ] }
    subject { DiffRange.create(array) }

    it "correctly skips the last position" do
      subject.skip_last
      expect(subject.first).to be == 0
      expect(subject.last).to be == 2
      expect(subject.size).to be == 3
    end

    it "correctly skips the last 3 positions" do
      3.times { subject.skip_last }
      expect(subject.first).to be == 0
      expect(subject.last).to be == 0
      expect(subject.size).to be == 1
    end

    it "does not skip beyond the first" do
      10.times { subject.skip_last }
      expect(subject.first).to be == 0
      expect(subject.last).to be == -1
      expect(subject.size).to be == 0
      expect(subject.empty?).to eq true
    end
  end
end
