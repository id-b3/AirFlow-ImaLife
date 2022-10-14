from pathlib import Path
import re
from itertools import repeat
import subprocess
import argparse
import logging
import time
from datetime import date, datetime
import multiprocessing.dummy as mp


def process_scan(scan_folder, dist_pen, dist_name, outdir):

    docker_name = "colossali/airflow:septest"
    input_dir = next(scan_folder.glob(r"**/*INSP*/"))
    vol_name = re.findall(r'\d\d\d\d\d\d', str(scan_folder))[0]
    outdir = outdir / vol_name / dist_name
    outdir.mkdir(parents=True, exist_ok=True)
    vol_name = vol_name + ".dcm"

    command_array = [
        "docker",
        "run",
        "--gpus",
        "all",
        "--rm",
        "-t",
        "-v",
        f"{input_dir}:/input",
        "-v",
        f"{outdir}:/output",
        docker_name,
        "/input",
        f"{dist_name}_{vol_name}",
        "/output",
        f"/output/{vol_name}.log",
        f"-i 50 -o 50 -I 7 -O 7 -d {dist_pen} -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.58 -G -0.68 -C 2"
    ]

    logging.debug(command_array)
    start_time = time.time()
    subprocess.run(command_array)
    execution_time = (time.time() - start_time) / 60
    logging.info(
        f",{date.today().strftime('%d-%m-%y')},{time.strftime('%H:%M')},{vol_name},{execution_time:.2f}"
    )


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()
    out_path = Path(dirs.out_dir).resolve()
    dist_penalty = [1.3, 1.5, 1.6, 1.7]
    dist_pen_name = ["1p3", "1p5", "1p6", "1p7"]
    p = mp.Pool(4)
    p.starmap(process_scan, zip(repeat(main_path), dist_penalty, dist_pen_name, repeat(out_path)))
    p.close()
    p.join()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "main_dir",
        type=str,
        help="Main folder containing repeat scans in subfolders.")
    parser.add_argument("out_dir", type=str, help="Output folder.")
    args = parser.parse_args()
    log_name = datetime.now().strftime("airflow_log_%d_%m_%Y_%H_%M.log")
    logging.basicConfig(filename=log_name, filemode="a", level=logging.INFO)

    main(args)
