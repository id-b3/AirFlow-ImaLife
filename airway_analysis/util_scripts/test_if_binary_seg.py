from airway_analysis.functionsutil.imagefilereaders import ImageFileReader
import argparse
import numpy as np
import matplotlib.pyplot as plt


def main(args):
    in_image = ImageFileReader.get_image(args.in_file)
    values = np.unique(in_image)
    print(f"Segmentation unique values: \n{values}")
    num_bins = 20
    density_range = False
    max_value = np.max(in_image)
    min_value = np.min(in_image)
    bins = np.linspace(min_value, max_value, num_bins)
    plt.hist(in_image.flatten(), bins=bins, log=True, density=density_range)
    plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Rescale image to desired resolution')
    parser.add_argument('-i', '--in_file', type=str, help='Input file', required=True)
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))
    main(args)
