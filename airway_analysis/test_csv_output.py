import argparse
from pathlib import Path
import sys

from bronchipy.tree.airwaytree import AirwayTree
from bronchipy.io import branchio as brio


def main(arguments) -> int:
    try:
        inner_df = brio.load_csv(arguments.norm_csv, inner=True)
        inner_locrad_df = brio.load_local_radius_csv(arguments.local_rad_csv, inner=True)
        print(inner_df.head())
        print(inner_locrad_df.head())
        airway_tree = AirwayTree()
        return 0
    except (OSError, TypeError) as e:
        print(f"Error: {e}")
        return 1


if __name__ == '__main__':
    aparse = argparse.ArgumentParser()
    aparse.add_argument("norm_csv", type=str, help="Input path for the csv file output from the gts_ray_measure tool.")
    aparse.add_argument("local_rad_csv", type=str, help="Input path for the csv file local_radius.")
    if len(sys.argv) == 1:
        aparse.print_help(sys.stderr)
        sys.exit()
    prsargs = aparse.parse_args()

    main(arguments=prsargs)
