
import argparse

from airway_analysis.functionsutil.filereader import ImageFileReader
from airway_analysis.functionsutil.functionutil import *
from airway_analysis.functionsutil.imageoperations import *


def main(args):

    in_filename_lumen = list_files_dir(args.input_dir, '*_surface0.dcm')[0]
    in_filename_outwall = list_files_dir(args.input_dir, '*_surface1.dcm')[0]

    in_list_boundboxes = list(np.load(args.in_boundboxes_file))

    for i, iboundox in enumerate(in_list_boundboxes):
        in_list_boundboxes[i] = tuple([tuple(iboundox[0]), tuple(iboundox[1]), tuple(iboundox[2])])

    in_image_lumen = ImageFileReader.get_image(in_filename_lumen)
    in_image_outwall = ImageFileReader.get_image(in_filename_outwall)

    in_image_metadata_lumen = ImageFileReader.get_image_metadata_info(in_filename_lumen)
    in_image_metadata_outwall = ImageFileReader.get_image_metadata_info(in_filename_outwall)

    # ----------

    # output files: 1 per cropped image to each bounding box
    out_template_subdirnames = dirname(in_filename_lumen).replace('/.', '_region%d/')

    for i, iboundox in enumerate(in_list_boundboxes):
        out_cropped_image_lumen = compute_cropped_image(in_image_lumen, iboundox)
        out_cropped_image_outwall = compute_cropped_image(in_image_outwall, iboundox)

        out_image_region_lumen = compute_setpatch_image(out_cropped_image_lumen, in_image_lumen.shape, iboundox)
        out_image_region_outwall = compute_setpatch_image(out_cropped_image_outwall, in_image_outwall.shape, iboundox)

        output_dir_region = out_template_subdirnames % (i + 1)

        makedir(output_dir_region)

        out_filename_lumen = join_path_names(output_dir_region, basename(in_filename_lumen))
        out_filename_outwall = join_path_names(output_dir_region, basename(in_filename_outwall))

        ImageFileReader.write_image(out_filename_lumen, out_image_region_lumen, metadata=in_image_metadata_lumen)
        ImageFileReader.write_image(out_filename_outwall, out_image_region_outwall, metadata=in_image_metadata_outwall)
    # endfor


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input_dir', type=str)
    parser.add_argument('--in_boundboxes_file', type=str, default='./boundboxes_regions_phantom.npy')
    args = parser.parse_args()

    main(args)
