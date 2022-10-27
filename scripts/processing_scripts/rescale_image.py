import logging
import argparse
import numpy as np

from bronchipy.util import ImageFileReader
from bronchipy.util import compute_rescaled_image, compute_thresholded_mask
from bronchipy.util import is_exist_file, handle_error_message


def rescale_img(in_file: str, out_file: str, resol: tuple, is_binary: bool):
    """
    Rescale the image to the desired resolution (voxel size)
    Parameters
    ----------
    in_file: str
        Path for the input image
    out_file: str
        Path for the output image
    resol: tuple
        Resolution of the output image (or voxel spacing)
    is_binary: bool
        Need to enable when rescaling a binary mask (to remove noise after interpolation)
    """
    logging.basicConfig(level=logging.INFO)

    in_image = ImageFileReader.get_image(args.in_file)
    logging.debug(f"Original image dims:\n {in_image.shape}")

    in_affine_matrix = ImageFileReader.get_image_metadata_info(args.in_file)
    logging.debug(f"Original affine matrix:\n {in_affine_matrix}")

    # to match the format of loaded nifti images (dz, dy, dx)
    args.resol = (args.resol[2], args.resol[1], args.resol[0])

    voxel_size = ImageFileReader.get_image_voxelsize(args.in_file)

    scale_factor = tuple([voxel_size[i] / args.resol[i] for i in range(3)])

    # apply 3rd order interpolation (cubic splines) for rescaling
    out_image = compute_rescaled_image(in_image, scale_factor, order=3)

    if args.is_binary:
        # remove noise due to interpolation of binary mask during rescaling
        thres_rm_noise = 0.5
        logging.debug(
            f"Binarise the output from rescaling, with threshold:\n {thres_rm_noise}"
        )

        out_image = compute_thresholded_mask(out_image, thres_rm_noise)

    # set the new resolution in the affine matrix
    for i in range(3):
        in_affine_matrix[i, i] = np.sign(in_affine_matrix[i, i]) * args.resol[i]

    logging.debug(f"New image dims:\n {out_image.shape}")
    logging.debug(f"New rescaled affine matrix:\n {in_affine_matrix}")
    ImageFileReader.write_image(args.out_file, out_image, metadata=in_affine_matrix)


def main(argmts):
    if not is_exist_file(argmts.in_file):
        message = "Input file '%s' does not exist" % (argmts.in_file)
        handle_error_message(message)

    rescale_img(argmts.in_file, argmts.out_file, args.resol, args.is_binary)


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    parser = argparse.ArgumentParser(description="Rescale image to desired resolution")
    parser.add_argument("-i", "--in_file", type=str, help="Input file", required=True)
    parser.add_argument("-o", "--out_file", type=str, help="Output file", required=True)
    parser.add_argument(
        "-r", "--resol", nargs=3, type=float, help="Final resolution", required=True
    )
    parser.add_argument(
        "--is_binary", type=bool, help="binarise the rescaled output ?", default=False
    )
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("'%s' = %s" % (key, value))
    main(args)
