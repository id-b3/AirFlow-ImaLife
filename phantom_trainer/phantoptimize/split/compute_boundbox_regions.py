
import argparse

from ..common.filereader import ImageFileReader
from ..common.imageoperations import *

NUM_VOXELS_BUFFER = 8


def comp_bound_box(input_file, output_file):

    in_image = ImageFileReader.get_image(input_file)

    (in_connected_labels_image, num_regions) = compute_connected_components(in_image)

    list_boundboxes_connected_images = []

    for ireg in range(num_regions):
        out_connected_image = (in_connected_labels_image == ireg + 1)

        out_boundbox_connected_image = compute_boundbox_around_mask(out_connected_image, NUM_VOXELS_BUFFER)
        list_boundboxes_connected_images.append(out_boundbox_connected_image)
    # endfor

    # ----------

    # output bounding boxes
    np.save(output_file, list_boundboxes_connected_images)

    output_file_csv = output_file.replace('.npy', '.csv')

    with open(output_file_csv, 'w') as fout:
        for i, iboundbox in enumerate(list_boundboxes_connected_images):
            fout.write("%s: %s\n" % ('case%d' % (i + 1), str(iboundbox)))


def main(argmts):
    comp_bound_box(argmts.input_file, argmts.output_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input_file', type=str, default='./phantom_lumen.dcm')
    parser.add_argument('--output_file', type=str, default='./boundboxes_split_regions_phantom.npy')
    args = parser.parse_args()

    main(args)
