import logging
import pandas as pd
from airway_analysis.bronchipy.calc.measure_airways import calc_pi10
from airway_analysis.bronchipy.io.branchio import load_pickle_tree
from pathlib import Path
import argparse
import sys


def main(dirs):

    main_path = Path(dirs.in_pickle).resolve()
    param_first_list = []
    param_repeat_list = []
    index_list = []

    outdir = Path(dirs.out_dir)
    param = dirs.param
    outdir.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(level=logging.INFO)

    for directory in main_path.iterdir():
        index_list.append(str(directory.stem))
        for index, scan_dir in enumerate(directory.iterdir()):
            if index == 0:
                param_name = f"{str(directory.stem)}_first"
            elif index == 1:
                param_name = f"{str(directory.stem)}_repeat"
            else:
                logging.debug("Error processing scan, too many in folder.")
                continue

            for child in scan_dir.iterdir():
                logging.debug(child.absolute().resolve())
                logging.debug(param_name)
                tree = load_pickle_tree(str(child.absolute().resolve()))
                tree = tree[tree.wall_global_area > 0.1]
                logging.debug(tree.wall_global_area)

                if param == "pi10":
                    pi10 = calc_pi10(
                        tree["wall_global_area"],
                        tree["inner_radius"],
                        save_dir=dirs.out_dir,
                        plot=True,
                        name=param_name,
                    )
                    if index == 0:
                        param_first_list.append(pi10)
                    else:
                        param_repeat_list.append(pi10)
                    logging.debug(f"Done {pi10}")

                    df = pd.DataFrame(
                        list(zip(index_list, param_first_list, param_repeat_list)),
                        columns=["ID", "Pi10_first", "Pi10_repeat"],
                    )
                    df.to_csv(str(Path(outdir / "results_pi10.csv").resolve()))

                elif param == "WAP":
                    wap_summary = tree.groupby("generation")[
                        "wall_global_area_perc"
                    ].describe()
                    if index == 0:
                        # file_name = f"results_wap_{str(directory.stem)}_first.csv"
                        param_first_list.append(wap_summary["mean"].values.tolist())
                    else:
                        # file_name = f"results_wap_{str(directory.stem)}_repeat.csv"
                        param_repeat_list.append(wap_summary["mean"].values.tolist())
                    df = pd.DataFrame(
                        list(zip(index_list, param_first_list, param_repeat_list)),
                        columns=["ID", "WAP_first", "WAP_repeat"],
                    )
                    # wap_summary.to_csv(f'{str(Path(outdir / file_name).resolve())}')
                    df.to_csv(str(Path(outdir / "results_wap.csv").resolve()))
                elif param == "Ai":
                    ai_summary = tree.groupby("generation")[
                        "inner_global_area"
                    ].describe()
                    if index == 0:
                        param_first_list.append(ai_summary["mean"].values.tolist())
                    else:
                        param_repeat_list.append(ai_summary["mean"].values.tolist())

                    df = pd.DataFrame(
                        list(zip(index_list, param_first_list, param_repeat_list)),
                        columns=["ID", "Ai_first", "Ai_repeat"],
                    )
                    # wap_summary.to_csv(f'{str(Path(outdir / file_name).resolve())}')
                    df.to_csv(str(Path(outdir / "results_ai.csv").resolve()))


if __name__ == "__main__":
    aparse = argparse.ArgumentParser()
    aparse.add_argument(
        "--in_pickle", type=str, help="Input path for the airway_summary pickle file."
    )
    aparse.add_argument(
        "--out_dir",
        type=str,
        help="Output folder for the results.",
        default="/eureka/output",
    )
    aparse.add_argument(
        "--param",
        type=str,
        help="Which bronchial parameters to calculate. Options: WA, WAP, Pi10, Ai, Ao, WT",
    )

    if len(sys.argv) == 1:
        aparse.logging.debug_help(sys.stderr)
        sys.exit(1)
    prsargs = aparse.parse_args()

    main(prsargs)
