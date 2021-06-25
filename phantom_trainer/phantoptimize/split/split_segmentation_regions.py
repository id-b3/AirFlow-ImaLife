import argparse
import logging
from ..common.filereader import ImageFileReader
from ..common.functionutil import *
from ..common.imageoperations import *


def split_seg_reg(in_dir: str, in_boxes: str, root_name: str = 'phantom_volume') -> str:
    in_filename_lumen = join_path_names(in_dir, f'./{root_name}_surface0.nii.gz')
    in_filename_outwall = join_path_names(in_dir, f'./{root_name}_surface1.nii.gz')
    logging.debug(f"Splitting in {in_dir} using {in_boxes}. \n{in_filename_lumen}\n{in_filename_outwall}")

    in_list_boundboxes = list(np.load(in_boxes))

    for i, iboundox in enumerate(in_list_boundboxes):
        in_list_boundboxes[i] = tuple([tuple(iboundox[0]), tuple(iboundox[1]), tuple(iboundox[2])])
        logging.debug(f"bounding boxes: {in_list_boundboxes[i]}")

    in_image_lumen = ImageFileReader.get_image(in_filename_lumen)
    in_image_outwall = ImageFileReader.get_image(in_filename_outwall)

    in_image_metadata_lumen = ImageFileReader.get_image_metadata_info(in_filename_lumen)
    logging.debug(in_image_metadata_lumen)
    in_image_metadata_outwall = ImageFileReader.get_image_metadata_info(in_filename_outwall)
    logging.debug(in_image_metadata_outwall)
    # ----------

    # output files: 1 per cropped image to each bounding box
    out_template_subdirnames = dirname(in_filename_lumen).replace('.', 'split_regions/')
    logging.debug(dirname(in_filename_lumen))
    logging.debug(out_template_subdirnames)

    for i, iboundox in enumerate(in_list_boundboxes):
        out_cropped_image_lumen = compute_cropped_image(in_image_lumen, iboundox)
        out_cropped_image_outwall = compute_cropped_image(in_image_outwall, iboundox)

        out_image_region_lumen = compute_setpatch_image(out_cropped_image_lumen, in_image_lumen.shape, iboundox)
        out_image_region_outwall = compute_setpatch_image(out_cropped_image_outwall, in_image_outwall.shape, iboundox)

        output_dir_region = out_template_subdirnames + f'region_{i+1}'
        logging.debug(output_dir_region)

        makedir(output_dir_region)

        out_filename_lumen = join_path_names(output_dir_region, './phantom_volume_surface0.nii.gz')
        out_filename_outwall = join_path_names(output_dir_region, './phantom_volume_surface1.nii.gz')

        ImageFileReader.write_image(out_filename_lumen, out_image_region_lumen, metadata=in_image_metadata_lumen)
        ImageFileReader.write_image(out_filename_outwall, out_image_region_outwall, metadata=in_image_metadata_outwall)

    return out_template_subdirnames


def main(argmts):
    split_seg_reg(argmts.input_dir, argmts.in_boundboxes_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input_dir', type=str)
    parser.add_argument('--in_boundboxes_file', type=str, default='./boundboxes_split_regions_phantom.npy')
    args = parser.parse_args()

    main(args)
