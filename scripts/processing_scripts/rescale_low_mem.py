import argparse

from ants import image_read, resample_image


def main(args):
    orig_image = image_read(args.i)
    resampled_image = resample_image(orig_image, (0.5, 0.5, 0.5), interp_type=1)
    resampled_image.to_file(args.o)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", type=str, help="Input image.")
    parser.add_argument("-o", type=str, help="Output image.")
    args = parser.parse_args()
    main(args)
