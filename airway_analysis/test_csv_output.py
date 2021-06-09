import argparse
import sys

from bronchipy.tree.airwaytree import AirwayTree


def main(file_list) -> int:
    try:
        airway_tree = AirwayTree(branch_file=file_list.branch_csv, inner_file=file_list.inner_csv,
                                 inner_radius_file=file_list.inner_rad_csv, outer_file=file_list.outer_csv,
                                 outer_radius_file=file_list.outer_rad_csv, volume=file_list.volume_nii)
        # airway_tree.tree.to_csv('..\\temp_test_files\\Analysis\\airway_tree_area.csv')
        print(airway_tree.get_branch(4))
        return 0
    except (OSError, TypeError) as e:
        print(f"Error: {e}")
        return 1


if __name__ == '__main__':
    aparse = argparse.ArgumentParser()
    aparse.add_argument("inner_csv", type=str,
                        help="Input path for the inner csv file output from the gts_ray_measure tool.")
    aparse.add_argument("inner_rad_csv", type=str,
                        help="Input path for the inner csv file local_radius.")
    aparse.add_argument("outer_csv", type=str,
                        help="Input path for the outer csv file output from the gts_ray_measure tool.")
    aparse.add_argument("outer_rad_csv", type=str,
                        help="Input path for the outer csv file local_radius.")
    aparse.add_argument("branch_csv", type=str,
                        help="Input path for the branches csv file output from the brh_translator tool.")
    aparse.add_argument("volume_nii", type=str,
                        help="Input path for the NIFTI format volume.")
    if len(sys.argv) == 1:
        aparse.print_help(sys.stderr)
        sys.exit()
    prsargs = aparse.parse_args()

    main(prsargs)
