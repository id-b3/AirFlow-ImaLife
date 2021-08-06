from collections import OrderedDict
import argparse
import csv

from airway_analysis.functionsutil.functionsutil import *
from airway_analysis.functionsutil.filereaders import ImageFileReader
from airway_analysis.functionsutil.imageoperations import compute_connected_components, compute_boundbox_around_mask

NUM_VOXELS_BUFFER = 8


def comp_bound_box(in_file: str, out_file: str):
    """
    Compute the bounding box regions for the phantom airways.

    Parameters
    ----------
    in_file: str
        Path for the input file (the initial phantom segmentation)
    out_file: str
        Path for the output file. Default: ./boundboxes_regions_phantom.pkl
    """
    in_image = ImageFileReader.get_image(in_file)

    (in_connected_regions, num_regions) = compute_connected_components(in_image)

    dict_boundboxes_regions = OrderedDict()

    for ireg in range(num_regions):
        out_region = (in_connected_regions == ireg + 1)

        out_boundbox_region = compute_boundbox_around_mask(out_region, NUM_VOXELS_BUFFER)
        dict_boundboxes_regions['reg%s' % (ireg + 1)] = out_boundbox_region
    # endfor

    # output bounding boxes
    save_dictionary(out_file, dict_boundboxes_regions)

    out_file_csv = out_file.replace('.pkl', '.csv')
    with open(out_file_csv, 'w') as fout:
        writer = csv.writer(fout)
        for key, value in dict_boundboxes_regions.items():
            writer.writerow([key, value])


def main(argmts):
    if not is_exist_file(argmts.in_file):
        message = 'Input file \'%s\' does not exist' % (argmts.in_file)
        handle_error_message(message)

    comp_bound_box(argmts.in_file, argmts.out_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Compute the bounding boxes around 8 the regions in COPDGene phantom')
    parser.add_argument('-i', '--in_file', type=str, help='Input file', required=True)
    parser.add_argument('-o', '--out_file', type=str, help='Output file', default='./boundboxes_regions_phantom.pkl')
    args = parser.parse_args()
    
    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))
    main(args)
