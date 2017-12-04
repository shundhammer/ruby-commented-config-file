#!/usr/bin/rspec
#
# Unit test for CommentedConfigFile
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require_relative "support/spec_helper"
require "etc_fstab"

# rubocop:disable Lint/AmbiguousRegexpLiteral
# rubocop:disable Style/RegexpLiteral
# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/LineLength

describe EtcFstab do
  context "with demo-fstab" do
    before(:all) { @fstab = described_class.new("data/demo-fstab") }
    subject { @fstab }

    describe "#new / #read" do
      it "has the expected number of entries" do
        expect(subject.entries.size).to eq 9
      end

      it "has the expected other devices" do
        devices =
          ["/dev/disk/by-label/swap",
           "/dev/disk/by-label/openSUSE",
           "/dev/disk/by-label/Ubuntu",
           "/dev/disk/by-label/work",
           "/dev/disk/by-label/Win-Boot",
           "/dev/disk/by-label/Win-App",
           "nas:/share/sh",
           "nas:/share/work",
           "//fritz.box/fritz.nas/"]
        expect(subject.devices).to eq devices
      end

      it "has the expected mount points" do
        mount_points =
          ["none",
           "/alternate-root",
           "/",
           "/work",
           "/win/boot",
           "/win/app",
           "/nas/sh",
           "/nas/work",
           "/fritz.nas"]
        expect(subject.mount_points).to eq mount_points
      end

      it "has the expected filesystem types" do
        fs_types =
          ["swap",
           "ext4",
           "ext4",
           "ext4",
           "ntfs",
           "ntfs",
           "nfs",
           "nfs",
           "cifs"]
        expect(subject.fs_types).to eq fs_types
      end

      it "all dump_pass fields are 0" do
        dump_pass = subject.entries.map(&:dump_pass)
        expect(dump_pass.count(0)).to be == 9
      end

      it "the root filesystem has the correct mount options and fsck pass" do
        entry = subject.find_mount_point("/")
        expect(entry).not_to be_nil
        expect(entry.mount_opts).to eq ["errors=remount-ro"]
        expect(entry.fsck_pass).to be == 1
      end

      it "the two Linux non-root partitions have fsck_pass 2" do
        entries = subject.entries.select { |e| e.fsck_pass == 2 }
        devices = entries.map { |e| e.device }
        expected_devices =
          ["/dev/disk/by-label/openSUSE",
           "/dev/disk/by-label/work"]
        expect(devices).to eq expected_devices
      end

      it "all non-ext4 filesystems have fsck_pass 0" do
        entries = subject.entries.reject { |e| e.fs_type == "ext4" }
        nonzero_fsck = entries.reject { |e| e.fsck_pass == 0 }
        expect(nonzero_fsck).to be_empty
      end

      it "the Windows boot partition has the correct mount options" do
        entry = subject.find_device("/dev/disk/by-label/Win-Boot")
        expect(entry).not_to be_nil
        expect(entry.mount_opts).to eq ["umask=007", "gid=46"]
      end
    end
  end
end
