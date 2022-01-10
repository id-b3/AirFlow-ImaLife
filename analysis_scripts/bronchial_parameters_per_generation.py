import logging
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path
import argparse
import statsmodels.api as sm
from multiprocessing import Pool
import sys
sys.path.append("")
from airway_analysis.bronchipy.calc.measure_airways import calc_pi10
from airway_analysis.bronchipy.io.branchio import load_pickle_tree


param = ""
outdir = None
in_args = None
logging.basicConfig()


def calculate_parameters(m_dir: Path, param, outdir):
    result_number = int(m_dir.stem)
    result = [result_number, 0, 0, 0, 0]
    for index, child_dir in enumerate(m_dir.iterdir()):

        if index == 0:
            res_name = f"{result_number}_first"
        elif index == 1:
            res_name = f"{result_number}_repeat"
        else:
            res_name = "ERROR"
            logging.error(f"Too many child directories in {result_number}")
        logging.debug(index)
        logging.debug(child_dir)
        if sum(1 for _ in child_dir.iterdir()) < 2:
            logging.error(f"Not enough files in {res_name}. Skipping.")
            with open('error_log.txt', 'a') as f:
                f.write(f'file_error,{res_name},{result_number}\n')
            continue
        for file_path in child_dir.iterdir():
            logging.debug(f"Scan folder: {file_path.absolute().resolve()}\n:{param}")
            file_str = str(file_path.absolute().resolve())
            if '.pickle' in file_str:
                logging.debug(f"Loading Pickle: {file_str}")
                tree = load_pickle_tree(file_str)
                tree = tree[tree.wall_global_area > 0.1]
            elif 'lung_volume.txt' in file_str:
                num_lines = sum(1 for line in open(file_str))
                if num_lines > 1:
                    logging.error(f"TOO MANY READINGS in {file_str}. Check scan folders for expiratory scans.")
                    with open('error_log.txt', 'a') as f:
                        f.write(f"multiple_readings,{res_name},{result_number}\n")
                    continue
                with open(file_str) as f:
                    if index == 0:
                        result[1] = (float(f.readline().strip()) / 1000000)
                    else:
                        result[3] = (float(f.readline().strip()) / 1000000)

            if param == 'pi10':
                try:
                    pi10 = calc_pi10(tree['wall_global_area'], tree['inner_radius'], save_dir=outdir, plot=True,
                                     name=res_name)
                    if index == 0:
                        result[2] = float(f"{pi10[0]:.4f}")
                    elif index == 1:
                        result[4] = float(f"{pi10[0]:.4f}")
                    logging.debug(f"Done processing pi10 for {res_name}")
                except:
                    logging.error(f"Error processing pi10 for {result_number}")
                    with open('error_log.txt', 'a') as f:
                        f.write(f"{file_str}\n")

    logging.info(result)
    return result


def main():
    global outdir
    global param
    main_path = Path(in_args.pickle_dir).resolve()
    main_dirs = [f for f in main_path.iterdir() if f.is_dir()]
    main_dirs.sort()
    result_list = []
    outdir = Path(in_args.out_dir)
    outdir.mkdir(parents=True, exist_ok=True)
    param = in_args.param.lower()
    logging.info(f"Starting to iterate through folders inside main path:\n"
                 f"{str(main_path)}\n"
                 f"{param}\n"
                 f"{str(outdir)}")
    iter_dir = iter(main_dirs)
    for dir_1 in iter_dir:
        # if all(False for _ in iter_dir):
        dir_2 = next(iter_dir)
        dir_3 = next(iter_dir)
        dir_4 = next(iter_dir)
        dirs = [dir_1, dir_2, dir_3, dir_4]
        params = [param, param, param, param]
        outdirs = [outdir, outdir, outdir, outdir]
        logging.debug(f"Directories for processing: \n{dir_1}\n{dir_2}\n{dir_3}\n{dir_4}")
        pool = Pool(4)
        results = pool.starmap(calculate_parameters, zip(dirs, params, outdirs))
        result_list.extend(results)

    if param == 'pi10':
        columns_csv = ['ID', 'first_vol', 'Pi10_first', 'second_vol', 'Pi10_repeat']
    else:
        logging.error("Wrong Parameter Entered.")

    df = pd.DataFrame(result_list, columns=columns_csv)
    if param == 'pi10':
        f, ax = plt.subplots(1, figsize=(8, 5))
        df = df[(df != 0).all(1)]
        sm.graphics.mean_diff_plot(df.Pi10_first, df.Pi10_repeat, ax=ax)
        plt.savefig(str(Path(outdir / f"bland_altmann_pi10.jpg").resolve()), dpi=300)
    df.to_csv(str(Path(outdir / f"results_{param}.csv").resolve()))


if __name__ == "__main__":
    aparse = argparse.ArgumentParser()
    aparse.add_argument("pickle_dir", type=str, help="Input directory path for pickle files.")
    aparse.add_argument("out_dir", type=str, help="Output folder for results.")
    aparse.add_argument("param", type=str, help="Bronchial Parameter to summarise. \n Options: WA%, Ai, Pi10.",
                        default="Pi10")
    aparse.add_argument("--debug", type=bool, help="Set logging level.", default=True)
    if len(sys.argv) < 1:
        aparse.print_help()
        sys.exit(1)
    in_args = aparse.parse_args()
    if in_args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
        # logging.basicConfig(level=logging.DEBUG, force=True)
        logging.debug("Enabled Debugging")
    elif not in_args.debug:
        logging.getLogger().setLevel(logging.INFO)
        # logging.basicConfig(level=logging.INFO)
    main()
