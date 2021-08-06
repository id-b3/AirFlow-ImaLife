import argparse
import logging
import numpy as np

from airway_analysis.functionsutil.functionsutil import *
from airway_analysis.functionsutil.filereaders import ImageFileReader
from airway_analysis.functionsutil.imageoperations import compute_cropped_image, compute_setpatch_image


def split_seg_reg(in_file: str, in_boxes_file: str, out_dir: str):
    logging.debug(f"Splitting {in_file} using {in_boxes_file}. Output results in {out_dir}")

    dict_boundboxes_regions = read_dictionary(in_boxes_file)

    for iboundox in dict_boundboxes_regions.values():
        iboundox = tuple([tuple(iboundox[0]), tuple(iboundox[1]), tuple(iboundox[2])])
        logging.debug(f"bounding boxes: {iboundox}")

    in_image = ImageFileReader.get_image(in_file)

    in_image_metadata = ImageFileReader.get_image_metadata_info(in_file)
    logging.debug(in_image_metadata)

    # output files: 1 per cropped image to each bounding box
    templ_output_filenames = join_path_names(out_dir, basename_filenoext(in_file) + '_region-%0.2i.nii.gz')
    logging.debug(templ_output_filenames)

    for i, iboundox in enumerate(dict_boundboxes_regions.values()):
        out_cropped_image = compute_cropped_image(in_image, iboundox)

        out_region_image = compute_setpatch_image(out_cropped_image, in_image.shape, iboundox)

        out_region_file = templ_output_filenames % (i + 1)
        print("Output file: \'%s\'..." %(out_region_file))

        ImageFileReader.write_image(out_region_file, out_region_image, metadata=in_image_metadata)


def main(argmts):
    if not is_exist_file(argmts.in_file):
        message = 'Input file \'%s\' does not exist' % (argmts.in_file)
        handle_error_message(message)
    if not is_exist_file(argmts.in_boxes_file):
        message = 'Input file of boxes \'%s\' does not exist' % (argmts.in_boxes_file)
        handle_error_message(message)
    if not is_exist_dir(argmts.out_dir):
        print("Output dir \'%s\' does not exist. Let's create it" % (argmts.in_file))

    split_seg_reg(argmts.in_file, argmts.in_boxes_file, args.out_dir)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Split segmentation in 8 regions present in the COPDGene phantom')
    parser.add_argument('-i', '--in_file', type=str, help='Input file', required=True)
    parser.add_argument('-ib', '--in_boxes_file', type=str, help='file with bounding boxes', default='./boundboxes_regions_phantom.pkl')
    parser.add_argument('-o', '--out_dir', type=str, help='Output dir', required=True)
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))
    main(args)
