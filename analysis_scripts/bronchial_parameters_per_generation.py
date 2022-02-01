import logging
from datetime import datetime
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path
import argparse
import statsmodels.api as sm
from sklearn import metrics
import seaborn as sns
import pingouin
from multiprocessing import Pool
import sys

sys.path.append("/home/ivan/AirSeg/Air_Flow_ImaLife")
# "/C:\\Users\\Ivan\\PyCharm\\AirFlow")
from airway_analysis.bronchipy.calc.measure_airways import calc_pi10
from airway_analysis.bronchipy.io.branchio import load_pickle_tree

param = ""


def plot_loa(x, y, generation):
    r2 = metrics.r2_score(x, y)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(8, 5))

    # sm.graphics.mean_diff_plot(x, y, ax=ax)
    # plt.savefig(str(Path(outdir / f"bland_altmann_pi10.jpg").resolve()), dpi=300)
    ping_fig = pingouin.plot_blandaltman(x, y, figsize=(8, 5), ax=ax1)
    sns.regplot(x, y, ax=ax2)
    props = dict(boxstyle="round", facecolor="wheat", alpha=0.5)
    text = f"$R^{2}$ = {r2:.3f}"
    ax2.text(
        0.05,
        0.95,
        text,
        transform=ax2.transAxes,
        fontsize=14,
        verticalalignment="top",
        bbox=props,
    )
    fig.tight_layout()
    fig.savefig(
        str(Path(outdir / f"bland_altmann_ping_{param}_{generation}.jpg").resolve()),
        dpi=300,
    )


def calculate_parameters(m_dir: Path, param, outdir, gen=0):
    result_number = int(m_dir.stem)
    result = [result_number, 0, 0, 0, 0]
    error = [0, 0]
    for index, child_dir in enumerate(m_dir.iterdir()):
        res_name = str(child_dir.stem)

        if sum(1 for _ in child_dir.iterdir()) < 2:
            logging.error(f"Not enough files in {res_name}. Skipping.")
            with open("error_log.csv", "a") as f:
                f.write(f"file_error,{res_name},{result_number}\n")
                error[0] = res_name
                error[1] = "file_error"
            continue
        for file_path in child_dir.iterdir():
            logging.debug(f"Scan folder: {file_path.absolute().resolve()}\n:{param}")
            file_str = str(file_path.absolute().resolve())
            res = 0
            vol = 0
            if ".pickle" in file_str:
                logging.debug(f"Loading Pickle: {file_str}")
                tree = load_pickle_tree(file_str)
                tree = tree[tree.wall_global_area > 0.1]
                if param == "pi10":
                    try:
                        tree = tree[tree.generation <= gen]
                        pi10 = calc_pi10(
                            tree["wall_global_area"],
                            tree["inner_radius"],
                            save_dir=outdir,
                            plot=True,
                            name=res_name,
                        )
                        res = float(f"{pi10[0]:.4f}")
                        logging.debug(f"Done processing pi10 for {res_name}")
                    except:
                        logging.error(f"Error processing pi10 for {result_number}\n{e}")
                        with open("error_log.csv", "a") as f:
                            f.write(f"{file_str}\n")
                elif param == "wa%" or param == "wap":
                    try:
                        wap_df = tree.groupby("generation")[
                            "wall_global_area_perc"
                        ].describe()
                        # wap_df.to_csv(str(Path(outdir / f"results_wap_{res_name}.csv").resolve()))
                        res = wap_df.at[gen, "mean"]
                    except (KeyError, TypeError) as e:
                        logging.error(f"Error processing wap for {result_number}\n {e}")
                elif param == "ai":
                    try:
                        ai_df = tree.groupby("generation")[
                            "inner_global_area"
                        ].describe()
                        res = ai_df.at[gen, "mean"]
                    except (KeyError, TypeError) as e:
                        logging.error(f"Error processing ai for {result_number}\n {e}")
                elif param == "count":
                    try:
                        count_df = tree.groupby("generation")[
                            "wall_global_thickness"
                        ].describe()
                        res = count_df["count"].to_numpy().tolist()
                    except (KeyError, TypeError) as e:
                        logging.error(
                            f"Error processing count for {result_number}\n {e}"
                        )

            elif "lung_volume.txt" in file_str:
                num_lines = sum(1 for line in open(file_str))
                if num_lines > 1:
                    logging.error(
                        f"TOO MANY READINGS in {file_str}. Check scan folders for expiratory scans."
                    )
                    error[0] = res_name
                    error[1] = "multiple_readings"
                    with open("error_log.csv", "a") as f:
                        f.write(f"multiple_readings,{res_name},{result_number}\n")
                    continue
                with open(file_str) as f:
                    vol = result[1] = float(f.readline().strip()) / 1000000

            if "first" in res_name:
                result[1] = vol
                result[2] = res
            elif "repeat" in res_name:
                result[3] = vol
                result[4] = res

    logging.info(result)
    return result, error


def main():
    global param
    main_path = Path(in_args.pickle_dir).resolve()
    main_dirs = [f for f in main_path.iterdir() if f.is_dir()]
    main_dirs.sort()
    for generation in in_args.generation:
        result_list = []
        error_list = []
        print(generation)
        param = in_args.param.lower()
        logging.info(
            f"Starting to iterate through folders inside main path:\n"
            f"{str(main_path)}\n"
            f"{param}\n"
            f"{str(outdir)}"
        )
        iter_dir = iter(main_dirs)
        for dir_1 in iter_dir:
            dir_2 = next(iter_dir)
            dir_3 = next(iter_dir)
            dir_4 = next(iter_dir)
            dirs = [dir_1, dir_2, dir_3, dir_4]
            params = [param, param, param, param]
            outdirs = [outdir, outdir, outdir, outdir]
            generations = [generation, generation, generation, generation]
            logging.debug(
                f"Directories for processing: \n{dir_1}\n{dir_2}\n{dir_3}\n{dir_4}"
            )
            pool = Pool(4)
            results, errors = zip(
                *pool.starmap(
                    calculate_parameters, zip(dirs, params, outdirs, generations)
                )
            )
            result_list.extend(results)
            error_list.extend(errors)

        if param == "pi10":
            columns_csv = ["ID", "first_vol", "Pi10_first", "second_vol", "Pi10_repeat"]
        elif param == "wa%" or param == "wap":
            columns_csv = [
                "ID",
                "first_vol",
                f"WAP_{generation}_first",
                "second_vol",
                f"WAP_{generation}_repeat",
            ]
        elif param == "ai":
            columns_csv = [
                "ID",
                "first_vol",
                f"AI_{generation}_first",
                "second_vol",
                f"AI_{generation}_repeat",
            ]
        elif param == "count":
            columns_csv = [
                "ID",
                "first_vol",
                f"count_{generation}_first",
                "second_vol",
                f"count_{generation}_repeat",
            ]
        else:
            logging.error("Wrong Parameter Entered.")

        df = pd.DataFrame(result_list, columns=columns_csv)
        edf = pd.DataFrame(error_list)
        df.reset_index(drop=True, inplace=True)
        #        df = df[(df != 0).all(1)]
        df = df[df.iloc[:, 2] > 0]
        df = df[df.iloc[:, 4] > 0]
        df["vol_diff"] = df["first_vol"] - df["second_vol"]
        df.to_csv(str(Path(outdir / f"results_{param}_{generation}.csv").resolve()))
        edf.to_csv(str(Path(outdir / f"errors_{param}_{generation}.csv").resolve()))
        plot_loa(df.iloc[:, 2], df.iloc[:, 4], generation)


if __name__ == "__main__":
    aparse = argparse.ArgumentParser()
    aparse.add_argument(
        "pickle_dir", type=str, help="Input directory path for pickle files."
    )
    aparse.add_argument("out_dir", type=str, help="Output folder for results.")
    aparse.add_argument(
        "param",
        type=str,
        help="Bronchial Parameter to summarise. \n Options: WA%, Ai, Pi10.",
        default="Pi10",
    )
    aparse.add_argument(
        "generation", nargs="+", type=int, help="Generations to summarise."
    )
    aparse.add_argument("--debug", type=bool, help="Set logging level.", default=False)
    if len(sys.argv) < 1:
        aparse.print_help()
        sys.exit(1)
    in_args = aparse.parse_args()
    outdir = Path(in_args.out_dir)
    outdir.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        filename=str(
            Path(
                outdir / f"error_log_{datetime.now().strftime('%d_%m_%H_%M')}.txt"
            ).resolve()
        )
    )
    if in_args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
        # logging.basicConfig(level=logging.DEBUG, force=True)
        logging.debug("Enabled Debugging")
    elif not in_args.debug:
        logging.getLogger().setLevel(logging.INFO)
        # logging.basicConfig(level=logging.INFO)
    main()
