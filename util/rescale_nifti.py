import argparse
import nibabel as nib
import numpy as np
from functionsutil.filereaders import ImageFileReader


def main(args):
    in_image = ImageFileReader.get_image(args.input_file)
    in_affine = ImageFileReader.get_image_metadata_info(args.input_file)
    print("Input Image Affine: {}".format(in_affine))

    # to match the format of loaded nifti images (dz, dy, dx)
    args.resol = (args.resol[2], args.resol[1], args.resol[0])

    # set the new resolution in the affine matrix
    for i in range(3):
        in_affine[i, i] = np.sign(in_affine[i, i]) * args.resol[i]

    print("Output Image Affine: {}".format(in_affine))
    # nib_image = nib.Nifti1Image(in_image, in_affine)
    ImageFileReader.write_image(args.output_file, in_image, metadata=in_affine)
    # nib.save(nib_image, args.output_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('input_file', type=str, help="Input the nifti file for rescaling.")
    parser.add_argument('output_file', type=str, help="Volume nifti file for rescaling.")
    parser.add_argument('-r', '--resol', nargs=3, type=float, help='Final resolution', required=True)
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))

    main(args)