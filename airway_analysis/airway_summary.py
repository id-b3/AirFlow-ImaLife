#!/usr/bin/env python3

import argparse
import sys

from bronchipy.tree.airwaytree import AirwayTree
from bronchipy.io import branchio as brio


def main(file_list) -> int:
    """
    Takes the output from the opfront method and parses it into an airway summary csv.

    Parameters
    ----------
    file_list: command line arguments

    Returns
    -------
    System code, 0 success, 1 error
    """

    try:
        airway_tree = AirwayTree(branch_file=file_list.branch_csv, inner_file=file_list.inner_csv,
                                 inner_radius_file=file_list.inner_rad_csv, outer_file=file_list.outer_csv,
                                 outer_radius_file=file_list.outer_rad_csv, volume=file_list.volume_nii)
        brio.save_summary_csv(airway_tree.tree, f"{file_list.output}/{file_list.name}_airway_tree_summary.csv")
        brio.save_pickle_tree(airway_tree.tree, f"{file_list.output}/{file_list.name}_airway_tree.pickle")
        return sys.exit()
    except (OSError, TypeError) as e:
        print(f"Error: {e}")
        return sys.exit(1)


if __name__ == '__main__':
    aparse = argparse.ArgumentParser()
    aparse.add_argument("--inner_csv", type=str,
                        help="Input path for the inner csv file output from the gts_ray_measure tool.")
    aparse.add_argument("--inner_rad_csv", type=str,
                        help="Input path for the inner csv file local_radius.")
    aparse.add_argument("--outer_csv", type=str,
                        help="Input path for the outer csv file output from the gts_ray_measure tool.")
    aparse.add_argument("--outer_rad_csv", type=str,
                        help="Input path for the outer csv file local_radius.")
    aparse.add_argument("--branch_csv", type=str,
                        help="Input path for the branches csv file output from the brh_translator tool.")
    aparse.add_argument("volume_nii", type=str,
                        help="Input path for the NIFTI format volume.")
    aparse.add_argument("--tree_csv", type=str, required=False,
                        help="Input path for the tree csv file output from the brh_translator tool.")
    aparse.add_argument("--output", type=str, help="Output folder for the airway summary csv and pickle files.",
                        default="/eureka/output")
    aparse.add_argument("--name", type=str, help="Name for the output summary file.")

    if len(sys.argv) == 1:
        aparse.print_help(sys.stderr)
        sys.exit(1)
    prsargs = aparse.parse_args()

    main(prsargs)
