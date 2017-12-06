#!/usr/bin/rspec
#
# Unit test for CommentedConfigFile
# (c) 2017 Stefan Hundhammer <Stefan.Hundhammer@gmx.de>
#
# License: GPL V2
#

require_relative "support/spec_helper"
require "etc_fstab"

describe EtcFstab do
  context "with demo-fstab" do
    before(:all) { @fstab = described_class.new("data/demo-fstab") }
    subject { @fstab }

    describe "Parser and access methods" do
      it "has the expected number of entries" do
        expect(subject.entries.size).to eq 9
      end

      it "has the expected devices" do
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

      it "the root filesystem has the correct mount options and fsck pass" do
        entry = subject.find_mount_point("/")
        expect(entry).not_to be_nil
        expect(entry.mount_opts).to eq ["errors=remount-ro"]
        expect(entry.fsck_pass).to be == 1
      end

      it "the /work filesystem has no mount options" do
        entry = subject.find_mount_point("/work")
        expect(entry).not_to be_nil
        expect(entry.mount_opts).to eq []
        expect(entry.mount_opts.empty?).to be true
      end

      it "the Windows boot partition has the correct mount options" do
        entry = subject.find_device("/dev/disk/by-label/Win-Boot")
        expect(entry).not_to be_nil
        expect(entry.mount_opts).to eq ["umask=007", "gid=46"]
      end

      it "the /fritz.nas partition's mount options are not cut off" do
        entry = subject.find_mount_point("/fritz.nas")
        expect(entry).not_to be_nil
        opts = entry.mount_opts.dup
        expect(opts.shift).to end_with("credentials.txt")
        expect(opts).to eq ["uid=sh", "forceuid", "gid=users", "forcegid"]
      end

      it "the two Linux non-root partitions have fsck_pass 2" do
        entries = subject.entries.select { |e| e.fsck_pass == 2 }
        devices = entries.map(&:device)
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

      it "all dump_pass fields are 0" do
        dump_pass = subject.entries.map(&:dump_pass)
        expect(dump_pass.count(0)).to be == 9
      end
    end

    describe "#fstab_encode" do
      it "escapes space characters correctly" do
        encoded = described_class.fstab_encode("very weird name")
        expect(encoded).to eq "very\\040weird\\040name"
      end
    end

    describe "#fstab_decode" do
      it "unescapes escaped space characters correctly" do
        decoded = described_class.fstab_decode("very\\040weird\\040name")
        expect(decoded).to eq "very weird name"
      end

      it "unescaping an escaped string with spaces results in the original" do
        orig = "very weird name"
        encoded = described_class.fstab_encode(orig)
        decoded = described_class.fstab_decode(encoded)
        expect(decoded).to eq orig
      end
    end

    describe "#get_mount_by" do
      it "correctly detects a device mounted by label" do
        entry = subject.find_mount_point("/work")
        expect(entry).not_to be_nil
        expect(entry.get_mount_by).to eq :label

        expect(described_class.get_mount_by("LABEL=work")).to eq :label
      end

      it "correctly detects a device mounted by UUID" do
        expect(described_class.get_mount_by("UUID=4711")).to eq :uuid
      end

      it "correctly detects a device mounted by device" do
        entry = subject.find_mount_point("/nas/work")
        expect(entry).not_to be_nil
        expect(entry.get_mount_by).to eq :device
      end

      it "correctly detects a device mounted by path" do
        expect(described_class.get_mount_by("/dev/disk/by-path/4711")).to eq :path
      end

    end

    describe "#check_mount_order" do
      it "detects a mount order problem" do
        expect(subject.check_mount_order).to be false
      end
    end

    describe "#next_mount_order_problem" do
      it "finds the mount order problem" do
        problem_index = subject.next_mount_order_problem
        expect(problem_index).to be == 2
        entry = subject.entries[problem_index]
        expect(entry).not_to be_nil
        expect(entry.mount_point).to eq "/"
      end
    end

    describe "#find_sort_index" do
      it "finds the correct place to move the problematic mount point to" do
        problem_index = 2
        entry = subject.entries[problem_index]
        expect(entry).not_to be_nil
        expect(subject.send(:find_sort_index, entry)).to be == 1
      end
    end

    describe "#fix_mount_order" do
      it "fixes the mount order problem" do
        new_fstab = subject.dup
        new_fstab.fix_mount_order
        mount_points =
          ["none",
           "/", # moved one position up
           "/alternate-root",
           "/work",
           "/win/boot",
           "/win/app",
           "/nas/sh",
           "/nas/work",
           "/fritz.nas"]
        expect(new_fstab.mount_points).to eq mount_points
        expect(new_fstab.check_mount_order).to be true
      end
    end
  end

  context "created empty" do
    subject { described_class.new }

    let(:root) do
      entry = EtcFstab::Entry.new
      entry.device = "/dev/sda1"
      entry.mount_point = "/"
      entry.fs_type = "ext4"
      entry
    end

    let(:var) do
      entry = EtcFstab::Entry.new
      entry.device = "/dev/sda2"
      entry.mount_point = "/var"
      entry.fs_type = "xfs"
      entry
    end

    let(:var_lib) do
      entry = EtcFstab::Entry.new
      entry.device = "/dev/sda3"
      entry.mount_point = "/var/lib"
      entry.fs_type = "jfs"
      entry
    end

    let(:var_lib_myapp) do
      entry = EtcFstab::Entry.new
      entry.device = "/dev/sda4"
      entry.mount_point = "/var/lib/myapp"
      entry.fs_type = "ext3"
      entry
    end

    let(:var_lib2) do
      entry = EtcFstab::Entry.new
      entry.device = "/dev/sda5"
      entry.mount_point = "/var/lib"
      entry.fs_type = "ext2"
      entry
    end

    describe "#add_entry" do
      it "adds entries in the correct sequence" do
        subject.add_entry(var_lib_myapp)
        subject.add_entry(var)
        subject.add_entry(var_lib)
        subject.add_entry(root)
        expect(subject.mount_points).to eq ["/", "/var", "/var/lib", "/var/lib/myapp"]
      end
    end

    describe "#fix_mount_order" do
      it "fixes a wrong mount order" do
        # Intentionally using the wrong superclass method to add items
        subject.entries << var_lib_myapp << var << var_lib << root

        # Wrong order as expected
        expect(subject.mount_points).to eq ["/var/lib/myapp", "/var", "/var/lib", "/"]
        expect(subject.check_mount_order).to be false

        expect(subject.fix_mount_order).to be true
        expect(subject.mount_points).to eq ["/", "/var", "/var/lib", "/var/lib/myapp"]
        expect(subject.check_mount_order).to be true
      end

      it "does not get an endless loop in the pathological case" do
        # Intentionally using the wrong superclass method to add items.
        subject.entries << var_lib << var_lib2 << var << root

        # Wrong order as expected
        expect(subject.mount_points).to eq ["/var/lib", "/var/lib", "/var", "/"]
        expect(subject.check_mount_order).to be false

        expect(subject.fix_mount_order).to be false
        expect(subject.mount_points).to eq ["/", "/var", "/var/lib", "/var/lib"]

        # There still is a problem; we couldn't fix it completely.
        # This is expected.
        expect(subject.check_mount_order).to be false
      end
    end

    describe "Entry#parse" do
      subject { EtcFstab::Entry.new }

      it "parses a correct entry correctly" do
        subject.parse("/dev/sda1 /data xfs defaults 0 1")
        expect(subject.device).to eq "/dev/sda1"
        expect(subject.mount_point).to eq "/data"
        expect(subject.fs_type).to eq "xfs"
        expect(subject.mount_opts).to eq []
        expect(subject.dump_pass).to eq 0
        expect(subject.fsck_pass).to eq 1
      end

      it "removes all 'defaults' from the mount options" do
        subject.parse("/dev/sda1 /data xfs ro,defaults,defaults,foo 0 1")
        expect(subject.mount_opts).to eq ["ro", "foo"]
      end

      it "throws an exception if the number of columns is wrong" do
        expect { subject.parse("/dev/sda1 /data xfs duh defaults 0 1", 42) }
          .to raise_error(EtcFstab::ParseError, /in line 43/)

        expect { subject.parse("/dev/sda1 /data xfs duh defaults 0 1") }
          .to raise_error(EtcFstab::ParseError, "Wrong number of columns")

        expect { subject.parse("/dev/sda1 /data defaults 0 1") }
          .to raise_error(EtcFstab::ParseError)
      end
    end

    describe "Entry#format" do
      subject { EtcFstab::Entry.new }

      it "formats a simple entry correctly" do
        subject.device = "/dev/sdb7"
        subject.mount_point = "/work"
        subject.fs_type = "ext4"
        subject.populate_columns
        expect(subject.format).to eq "/dev/sdb7  /work  ext4  defaults  0  0"
      end
    end

    describe "#format_lines" do
      subject { described_class.new }

      it "formats a simple entry correctly" do
        entry = subject.create_entry
        entry.device = "/dev/sdk3"
        entry.mount_point = "/work"
        entry.fs_type = "ext4"
        entry.mount_opts << "ro" << "foo" << "bar"
        subject.add_entry(entry)
        subject.output_delimiter = " "

        expect(subject.entries.size).to eq 1
        expect(subject.entries.first).to equal(entry)
        expect(subject.format_lines).to eq ["/dev/sdk3 /work ext4 ro,foo,bar 0 0"]
      end
    end
  end
end
