import numpy as np
import matplotlib.pyplot as plt
import argparse
import sys

sys.path.append("/bronchinet/")
from AirMorph.lungct import LungCT


def main(args):
    print(f"Making Segmentation Thumbnail:\n{args.in_seg}\n{args.out_img}")
    air_seg = LungCT(args.in_seg)
    f, axarr = plt.subplots(1, 3, figsize=(42, 12))
    axarr[0].imshow(
        np.rot90(air_seg.image.sum(axis=0)), interpolation="hanning", cmap="gray"
    )
    axarr[1].imshow(
        np.rot90(air_seg.image.sum(axis=1)), interpolation="hanning", cmap="gray"
    )
    axarr[2].imshow(air_seg.image.sum(axis=2), interpolation="hanning", cmap="gray")
    axarr[0].axis("off")
    axarr[1].axis("off")
    axarr[2].axis("off")
    plt.tight_layout()
    f.savefig(f"{args.out_img}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("in_seg", type=str, help="Input segmentation file.")
    parser.add_argument("out_img", type=str, help="Output segmentation file.")
    in_args = parser.parse_args()
    main(in_args)
