import nibabel as nib
import argparse


def main(args):
    image = nib.load(args.input_volume)
    print("Header: \n{}".format(image.header))
    print("Affine: \n{}".format(image.affine))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input_volume", type=str, help="Volume nifti file to print header and affine."
    )
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("'%s' = %s" % (key, value))

    main(args)
