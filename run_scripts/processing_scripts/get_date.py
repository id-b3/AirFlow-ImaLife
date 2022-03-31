from pydicom import dcmread
import argparse


def main(args):
    image = dcmread(args.image, force=True)
    date = image.AcquisitionDate
    with open(args.date_file, 'w') as f:
        f.write(date)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=str, help="DICOM Image to read date.")
    parser.add_argument("date_file", type=str, help="Scan date file.")
    args = parser.parse_args()

    main(args)
