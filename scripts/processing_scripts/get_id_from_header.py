from pathlib import Path
import pydicom
import argparse


def main(args):
    in_dir = Path(args.in_dir)
    slice = next(in_dir.glob("*.dcm"))

    participant_id = pydicom.dcmread(str(slice)).PatientID
    with open("./participant_id.txt", "w") as f:
        f.write(participant_id)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("in_dir", type=str, help="Input Directory")
    args = parser.parse_args()

    main(args)
