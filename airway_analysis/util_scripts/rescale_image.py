import logging
import argparse

# from airway_analysis.functionsutil.functionsutil import *
from airway_analysis.functionsutil.filereaders import ImageFileReader
from airway_analysis.functionsutil.imageoperations import compute_rescaled_image#, compute_thresholded_mask


def main(args):
    logging.basicConfig(level=logging.INFO)

    in_image = ImageFileReader.get_image(args.in_file)
    logging.info(f"Original image dims:\n {in_image.shape}")

    in_affine_matrix = ImageFileReader.get_image_metadata_info(args.in_file)
    logging.info(f"Original affine matrix:\n {in_affine_matrix}")

    # to match the format of loaded nifti images (dz, dy, dx)
    args.resol = (args.resol[2], args.resol[1], args.resol[0])

    voxel_size = ImageFileReader.get_image_voxelsize(args.in_file)

    scale_factor = tuple([voxel_size[i] / args.resol[i] for i in range(3)])

    # apply 3rd order interpolation (cubic splines) for rescaling
    out_image = compute_rescaled_image(in_image, scale_factor, order=3)
    logging.info(f"New image dims:\n {out_image.shape}")

    # THIS STEP IS NOT NEEDED IS OUTPUT OPFRONT SEGMENTATIONS ARE NOT BINARY BY DEFAULT
    # # remove noise due to interpolation in rescaling
    # thres_rm_noise = 0.5
    # out_image = compute_thresholded_mask(out_image, thres_rm_noise)

    # set the new resolution in the affine matrix
    for i in range(3):
        in_affine_matrix[i, i] = args.resol[i]

    logging.info(f"New rescaled affine matrix:\n {in_affine_matrix}")
    ImageFileReader.write_image(args.out_file, out_image, metadata=in_affine_matrix)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Rescale image to desired resolution')
    parser.add_argument('-i', '--in_file', type=str, help='Input file', required=True)
    parser.add_argument('-o', '--out_file', type=str, help='Output file', required=True)
    parser.add_argument('-r', '--resol', nargs=3, type=float, help='Final resolution', required=True)
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))
    main(args)
