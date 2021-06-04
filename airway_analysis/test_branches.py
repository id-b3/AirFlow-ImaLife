import argparse
from pathlib import Path
import sys

from bronchipy.tree.airwaytree import AirwayTree
from bronchipy.io import branchio


def print_airway_count(volume_name: str, airnum: int) -> None:
    print(f"Number of airways for the '{volume_name}' scan is {airnum}")


def print_dims(volume_name: str, pix_dim: list, vol_dim: list) -> None:
    print(f"The image dimensions for '{volume_name}' are {vol_dim[0]}x {vol_dim[1]}y {vol_dim[2]}z")
    print(f"The voxel dimentions for '{volume_name}' are {pix_dim[0]:.2f}x {pix_dim[1]:.3f}y {pix_dim[2]:.3f}z")


def main(arguments) -> int:
    """Script for testing the output of various bronchipy tools."""
    try:
        tree = AirwayTree(arguments.branch_csv, arguments.main_vol).get
        vol_name = Path(arguments.main_vol).stem
        pix_dims = tree.vol_vox_dims
        print_airway_count(vol_name, tree.get_airway_count())
        print_dims(vol_name, tree.vol_vox_dims, tree.vol_dims)
        # branchio.save_as_csv(branchio.load_brh_csv(arguments.branch_csv), "../temp_test_files/brh.csv")
        return 0
    except (OSError, TypeError):
        return 1


if __name__ == '__main__':
    aparse = argparse.ArgumentParser()
    aparse.add_argument("branch_csv", type=str, help="Input path for the csv file output from the brh_translator tool.")
    aparse.add_argument("main_vol", type=str, help="Input path for the main volume in the NIFTI format (.nii.gz)")
    if len(sys.argv) == 1:
        aparse.print_help(sys.stderr)
        sys.exit()
    prsargs = aparse.parse_args()

    main(arguments=prsargs)
