#!/usr/bin/env python3

import pydicom
import sys


def main(in_file, out_file):
    corrupt_scan = pydicom.dcmread(in_file)
    print(
        f'Converting Transfer Syntax from "{corrupt_scan.file_meta.TransferSyntaxUID}" '
        f'to "1.2.840.10008.1.2.4.70"'
    )
    corrupt_scan.file_meta.TransferSyntaxUID = "1.2.840.10008.1.2.4.70"
    print("Saving to {}".format(out_file))
    corrupt_scan.save_as(out_file)


if __name__ == "__main__":
    print(sys.argv)
    # in_file = glob(sys.argv[1])[0]
    in_file = sys.argv[1]
    out_file = sys.argv[2]
    print("Fixing Transfer Syntac in: {}".format(in_file))
    print("Output file: {}".format(out_file))

    # execute only if run as a script
    main(in_file, out_file)
