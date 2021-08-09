
import numpy as np
import argparse
import logging

from airway_analysis.functionsutil.functionsutil import *
from airway_analysis.functionsutil.imagefilereaders import ImageFileReader
from airway_analysis.functionsutil.imageoperations import compute_cropped_image, compute_extended_image


def split_seg_reg(in_file: str, in_boxes_file: str, out_dir: str):
    """
    Split the input segmentations into as many files as regions in the phantom airways.

    Parameters
    ----------
    in_file: str
        Path for the input file (the initial phantom segmentation)
    in_boxes_file: str
        Path for the file with coordinates of bounding boxes of regions (Default: ./boundboxes_regions_phantom.pkl)
    out_dir: str
        Path for the output files
    """
    logging.debug(f"Splitting {in_file} using {in_boxes_file}. Output results in {out_dir}")

    in_image = ImageFileReader.get_image(in_file)

    in_image_metadata = ImageFileReader.get_image_metadata_info(in_file)
    logging.debug(in_image_metadata)

    dict_boundboxes_regions = read_dictionary(in_boxes_file)

    # output files: 1 per cropped image to each bounding box
    templ_output_filenames = join_path_names(out_dir, basename_filenoext(in_file) + '_region-%0.2i.nii.gz')
    logging.debug(templ_output_filenames)

    for i, iboundox in enumerate(dict_boundboxes_regions.values()):
        logging.debug(f"Calc region {i + 1}, with bounding box: {iboundox}")

        out_cropped_image = compute_cropped_image(in_image, iboundox)

        out_region_image = compute_extended_image(out_cropped_image, in_image.shape, iboundox)

        out_region_file = templ_output_filenames % (i + 1)
        logging.debug(f"Output file: {out_region_file}, with dims: {out_region_image.shape}")

        ImageFileReader.write_image(out_region_file, out_region_image, metadata=in_image_metadata)
    # endfor


def main(argmts):
    if not is_exist_file(argmts.in_file):
        message = 'Input file \'%s\' does not exist' % (argmts.in_file)
        handle_error_message(message)
    if not is_exist_file(argmts.in_boxes_file):
        message = 'Input file of boxes \'%s\' does not exist' % (argmts.in_boxes_file)
        handle_error_message(message)
    if not is_exist_dir(argmts.out_dir):
        print("Output dir \'%s\' does not exist. Let's create it" % (argmts.out_dir))

    split_seg_reg(argmts.in_file, argmts.in_boxes_file, args.out_dir)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Split segmentation in the 8 regions in phantom')
    parser.add_argument('-i', '--in_file', type=str, help='Input file', required=True)
    parser.add_argument('-ib', '--in_boxes_file', type=str, help='file with bounding boxes', default='./boundboxes_regions_phantom.pkl')
    parser.add_argument('-o', '--out_dir', type=str, help='Output dir', required=True)
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))
    main(args)
