#!/usr/bin/env python3

import argparse
import csv
import logging
import sys

from bronchipy.calc.measure_airways import calc_pi10
from bronchipy.calc.summary_stats import param_by_gen, total_count
from bronchipy.io import branchio as brio
from bronchipy.tree.airwaytree import AirwayTree


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
        airway_tree = AirwayTree(
            branch_file=file_list.branch_csv,
            inner_file=file_list.inner_csv,
            inner_radius_file=file_list.inner_rad_csv,
            outer_file=file_list.outer_csv,
            outer_radius_file=file_list.outer_rad_csv,
            volume=file_list.volume_nii,
        )
        brio.save_summary_csv(airway_tree.tree, f"{file_list.output}/airway_tree.csv")
        brio.save_pickle_tree(
            airway_tree.tree, f"{file_list.output}/airway_tree.pickle"
        )

        # Calculate bronchial parameters
        pi10_tree = airway_tree.tree[
            (airway_tree.tree.generation > 1) & (airway_tree.tree.generation <= 6)
        ]
        logging.info(f"Calculating Pi10 for generations {pi10_tree.generation.unique()}")
        pi10 = calc_pi10(
            pi10_tree["wall_global_area"],
            pi10_tree["inner_radius"],
            name="pi10_graph",
            save_dir=file_list.output,
            plot=True,
        )

        wap = []
        la = []
        wt = []
        inr = []
        outr = []
        air_seg_error = 0

        for gen in range(0, 9):
            try:
                wap.append(param_by_gen(airway_tree.tree, gen, "wall_global_area_perc"))
                la.append(param_by_gen(airway_tree.tree, gen, "inner_global_area"))
                wt.append(param_by_gen(airway_tree.tree, gen, "wall_global_thickness"))
                inr.append(param_by_gen(airway_tree.tree, gen, "inner_radius"))
                outr.append(param_by_gen(airway_tree.tree, gen, "outer_radius"))
            except(KeyError) as e:
                print(f"No more generations: {gen}\n{e}")
                air_seg_error = 1
        tcount = total_count(airway_tree.tree)
        if tcount <= 100:
            air_seg_error = 1

        wap_str = ";".join(list(map(str, wap)))
        la_str = ";".join(list(map(str, la)))
        wt_str = ";".join(list(map(str, wt)))
        inr_str = ";".join(list(map(str, inr)))
        outr_str = ";".join(list(map(str, outr)))

        # Save bronchial parameters to file.
        bp_head = [
            "bp_tlv",
            "bp_airvol",
            "bp_wap",
            "bp_la",
            "bp_wt",
            "bp_ir",
            "bp_or",
            "bp_tcount",
            "bp_pi10",
            "bp_seg_performed",
            "bp_seg_error"
        ]
        bp_list = [0, 0, wap_str, la_str, wt_str, inr_str, outr_str, tcount, pi10, 1, air_seg_error]
        with open(f"{file_list.output}/bp_summary_redcap.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerow(bp_head)
            writer.writerow(bp_list)

        return sys.exit()
    except (OSError, TypeError) as e:
        print(f"Error: {e}")
        return sys.exit(1)


if __name__ == "__main__":
    aparse = argparse.ArgumentParser()
    aparse.add_argument(
        "--inner_csv",
        type=str,
        help="Input path for the inner csv file output from the gts_ray_measure tool.",
    )
    aparse.add_argument(
        "--inner_rad_csv",
        type=str,
        help="Input path for the inner csv file local_radius.",
    )
    aparse.add_argument(
        "--outer_csv",
        type=str,
        help="Input path for the outer csv file output from the gts_ray_measure tool.",
    )
    aparse.add_argument(
        "--outer_rad_csv",
        type=str,
        help="Input path for the outer csv file local_radius.",
    )
    aparse.add_argument(
        "--branch_csv",
        type=str,
        help="Input path for the branches csv file output from the brh_translator tool.",
    )
    aparse.add_argument(
        "volume_nii", type=str, help="Input path for the NIFTI format volume."
    )
    aparse.add_argument(
        "--tree_csv",
        type=str,
        required=False,
        help="Input path for the tree csv file output from the brh_translator tool.",
    )
    aparse.add_argument(
        "--output",
        type=str,
        help="Output folder for the airway summary csv and pickle files.",
        default="/eureka/output",
    )
    aparse.add_argument("--name", type=str, help="Name for the output summary file.")

    if len(sys.argv) == 1:
        aparse.print_help(sys.stderr)
        sys.exit(1)
    prsargs = aparse.parse_args()

    main(prsargs)
