from pathlib import Path
import re
from itertools import repeat
import subprocess
import argparse
import logging
import time
from datetime import date, datetime
import multiprocessing.dummy as mp
from tqdm import tqdm


def process_scan(scan_folder, outdir):

    docker_name = "colossali/airflow:eureka_v2"
    input_dir = next(scan_folder.glob(r"**/*INSP*/"))
    vol_name = re.findall(r'\d\d\d\d\d\d', str(scan_folder))[0]
    outdir = outdir / vol_name
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
        vol_name,
        "/output",
        f"/output/{vol_name}.log",
    ]

    logging.debug(command_array)
    start_time = time.time()
    run = subprocess.run(command_array)
    execution_time = (time.time() - start_time) / 60
    logging.info(
        f",{date.today().strftime('%d-%m-%y')},{time.strftime('%H:%M')},{vol_name},{run},{execution_time:.2f}"
    )


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()
    main_dirs = [d for d in main_path.iterdir() if d.is_dir()]
    out_path = Path(dirs.out_dir).resolve()
    main_dirs.sort()
    p = mp.Pool(4)
    list(
        tqdm(p.starmap(process_scan, zip(main_dirs, repeat(out_path))),
             total=len(main_dirs)))
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
