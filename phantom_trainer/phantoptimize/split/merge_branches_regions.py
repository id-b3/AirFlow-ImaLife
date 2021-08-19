import numpy as np
from collections import OrderedDict
import argparse
import logging

from functionsutil.functionsutil import *
from functionsutil.filereaders import BranchFileReader
from functionsutil.imagefilereaders import ImageFileReader
from functionsutil.imageoperations import compute_cropped_image, compute_setpatch_image


def merge_branch_reg(in_dir: str, out_file: str, is_merge_vols: bool, in_boxes_file: str, out_vol_file: str,
                     log_lev: int = logging.DEBUG):
    """
    Merge the extracted branch '.brh' files from the segmentations in regions in the phantom airways.

    Parameters
    ----------
    in_dir: str
        Path where to find the input '.brh' and '.nii.gz' files in the regions
    out_file: str
        Path for the output file with merged branches
    is_merge_vols: bool
        Option to merge the volume masks of segmentations in the regions
    in_boxes_file: str
        Path for the file with coordinates of bounding boxes of regions (Default: ./boundboxes_regions_phantom.pkl)
    out_vol_file: str
        Path for the output file with merged volume masks
    log_lev: int
        Logging Level
    """
    logging.basicConfig(level=log_lev)
    logging.debug(f"Merge branches found in {in_dir} and output file {out_file}")

    list_in_branch_files = list_files_dir(in_dir, "*-branch.brh")
    num_regions = len(list_in_branch_files)
    logging.debug(f"Found {num_regions} files with branches: {list_in_branch_files}")

    out_branch_data_all = OrderedDict()
    out_branch_data_all['index'] = []
    out_branch_data_all['parent'] = []
    out_branch_data_all['generation'] = []
    out_branch_data_all['ignore'] = []
    out_branch_data_all['maxRadius'] = []
    out_branch_data_all['children'] = []
    out_branch_data_all['points'] = []

    count_branches_all = 0
    curr_offset_index_branch = 0

    for ibranch_file in list_in_branch_files:
        logging.debug(f"Current Branch offset: {curr_offset_index_branch}")
        logging.debug(f"Input branch file: {ibranch_file}")

        in_branch_data = BranchFileReader.get_data(ibranch_file)
        logging.debug(f"Input Branch Data: {in_branch_data}")

        num_branches = max(in_branch_data['index'])
        count_branches_all += num_branches

        # to merge the branches, offset the "index", "parent" and "children" data by the index of last branch visited
        in_branch_data['index'] = [ind + curr_offset_index_branch for ind in in_branch_data['index']]
        logging.debug(f"Merging branch indexes {in_branch_data['index']}")
        in_branch_data['parent'] = [ind + curr_offset_index_branch if ind >0 else 0 for ind in in_branch_data['parent']]
        in_branch_data['children'] = [[ind + curr_offset_index_branch for ind in in_children_brh]
                                      for in_children_brh in in_branch_data['children']]

        # add data for this branch to the full datastr
        out_branch_data_all['index'] += in_branch_data['index']
        out_branch_data_all['parent'] += in_branch_data['parent']
        out_branch_data_all['generation'] += in_branch_data['generation']
        out_branch_data_all['ignore'] += in_branch_data['ignore']
        out_branch_data_all['maxRadius'] += in_branch_data['maxRadius']
        out_branch_data_all['children'] += in_branch_data['children']
        out_branch_data_all['points'] += in_branch_data['points']

        curr_offset_index_branch += num_branches

    # endfor

    BranchFileReader.write_data(out_file, out_branch_data_all)

    # Merge the separated branch volume files.
    if is_merge_vols:
        logging.debug(f"Merge the labelled volume masks of branches found in {in_dir} and output file {out_vol_file}")

        list_in_volmask_files = list_files_dir(in_dir, '*-branch.nii.gz')
        num_regions = len(list_in_volmask_files)
        logging.debug(f"Found {num_regions} files with volume masks of branches: {list_in_volmask_files}")

        dict_boundboxes_regions = read_dictionary(in_boxes_file)
        list_boundboxes_regions = list(dict_boundboxes_regions.values())

        size_out_image = ImageFileReader.get_image_size(list_in_volmask_files[0])
        out_volmask_all = np.zeros(size_out_image)

        curr_offset_index_branch = 0

        for i, ivolmask_file in enumerate(list_in_volmask_files):
            logging.debug(f"Input volume file: {ivolmask_file}")

            iboundox = list_boundboxes_regions[i]
            logging.debug(f"Branch in this volume inside the bounding: {iboundox}")
            logging.debug(f"Branch {i}")

            in_volmask = ImageFileReader.get_image(ivolmask_file)
            in_cropped_volmask = compute_cropped_image(in_volmask, iboundox)

            # to merge the masks, offset the labels by the label of the last branch visited
            in_cropped_volmask = np.where(in_cropped_volmask > 0, in_cropped_volmask + curr_offset_index_branch, 0)

            out_volmask_all = compute_setpatch_image(in_cropped_volmask, out_volmask_all, iboundox)

            curr_offset_index_branch += np.max(in_volmask)
        # endfor

        out_image_metadata = ImageFileReader.get_image_metadata_info(list_in_volmask_files[0])

        ImageFileReader.write_image(out_vol_file, out_volmask_all, metadata=out_image_metadata)


def main(argmts):
    if not is_exist_dir(argmts.in_dir):
        message = 'Input dir \'%s\' does not exist' % (argmts.in_dir)
        handle_error_message(message)
    if argmts.is_merge_vols:
        if not is_exist_file(argmts.in_boxes_file):
            message = 'Input file of boxes \'%s\' does not exist' % (argmts.in_boxes_file)
            handle_error_message(message)

    merge_branch_reg(argmts.in_dir, argmts.out_file, argmts.is_merge_vols, argmts.in_boxes_file, argmts.out_vol_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Merge branches extracted in the 8 regions in phantom')
    parser.add_argument('-i', '--in_dir', type=str, help='Input dir with branches', required=True)
    parser.add_argument('-o', '--out_file', type=str, help='Output file', required=True)
    parser.add_argument('--is_merge_vols', type=bool, help='merge the volume mask of branches ?', default=False)
    parser.add_argument('-ib', '--in_boxes_file', type=str, help='file with bounding boxes',
                        default='./boundboxes_regions_phantom.pkl')
    parser.add_argument('-ov', '--out_vol_file', type=str, help='Output segmentation file', required=False)
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))
    main(args)
