import argparse
import nibabel as nib


def main(args):
    vol_affine = nib.load(args.input_volume).affine
    print("Original Image Affine: {}".format(vol_affine))

    in_image_whole = nib.load(args.input_file)
    in_image = in_image_whole.get_fdata()
    in_affine = in_image_whole.affine
    print("Input Image Affine: {}".format(in_affine))
    nib_image = nib.Nifti1Image(in_image, vol_affine)
    nib.save(nib_image, args.input_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input_file", type=str, help="Input the nifti file for correction of headers."
    )
    parser.add_argument(
        "input_volume",
        type=str,
        help="Volume nifti file containing the correct headers.",
    )
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("'%s' = %s" % (key, value))

    main(args)
