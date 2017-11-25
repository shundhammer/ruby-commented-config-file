#!/usr/bin/rspec
#
# Unit test for CommentedConfigFile
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require_relative "support/spec_helper"
require "commented_config_file"

describe CommentedConfigFile do

  context "when created empty" do
    subject { described_class.new }

    describe "#new" do
      it "has no content" do
        expect(subject.header_comments).to be_nil
        expect(subject.footer_comments).to be_nil
        expect(subject.entries).to be_nil
        expect(subject.filename).to be_nil
      end
    end

    describe "#header_comments?" do
      it "is false" do
        expect(subject.header_comments?).to eq false
      end
    end

    describe "#footer_comments?" do
      it "is false" do
        expect(subject.footer_comments?).to eq false
      end
    end
  end
end
