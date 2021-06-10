import argparse
import sys

from bronchipy.tree.airwaytree import AirwayTree
from bronchipy.calc import measureAirways
from bronchipy.io import branchio as brio


def main(file_list) -> int:
    try:
        # airway_tree = AirwayTree(branch_file=file_list.branch_csv, inner_file=file_list.inner_csv,
        #                          inner_radius_file=file_list.inner_rad_csv, outer_file=file_list.outer_csv,
        #                          outer_radius_file=file_list.outer_rad_csv, volume=file_list.volume_nii)
        airway_tree = AirwayTree(tree_csv=file_list.tree_csv,
                                 volume=file_list.volume_nii)
        # brio.save_as_csv(airway_tree.tree, "..\\temp_test_files\\Analysis\\airway_tree.csv")
        branch_id = 3
        branch_length = measureAirways.calc_branch_length(airway_tree.get_branch(branch_id).points)
        # print(airway_tree.get_branch(4))
        print(f"Airway branch {branch_id} csv_length: {airway_tree.get_branch(branch_id).length}")
        return 0
    except (OSError, TypeError) as e:
        print(f"Error: {e}")
        return 1


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
    aparse.add_argument("--tree_csv", type=str,
                        help="Input path for the tree csv file output from the brh_translator tool.")
    if len(sys.argv) == 1:
        aparse.print_help(sys.stderr)
        sys.exit()
    prsargs = aparse.parse_args()

    main(prsargs)
