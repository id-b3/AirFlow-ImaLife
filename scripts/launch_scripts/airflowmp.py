#!/usr/bin/env python3

from pathlib import Path
from itertools import repeat
import subprocess
import argparse
import logging
import time
from datetime import date, datetime
import multiprocessing.dummy as mp

from tqdm import tqdm


def process_scan(scan_folder, outdir, completedir, faileddir):

    if scan_folder == completedir:
        print("Skipping completed_scans folder...")
        return
    elif scan_folder == faileddir:
        print("Skipping failed_scans folder...")
        return

    docker_name = "airflow:imalife_base"

    command_array = [
        "docker",
        "run",
        "--gpus",
        "all",
        "--rm",
        "-t",
        "-v",
        f"{scan_folder}:/input",
        "-v",
        f"{outdir}:/output",
        docker_name,
        "/input",
        "/output",
    ]

    logging.debug(command_array)
    start_time = time.time()
    run = subprocess.run(command_array)

    if run.returncode == 0:
        final_path = completedir / scan_folder.stem
        final_path.mkdir(parents=True, exist_ok=True)
        try:
            scan_folder.rename(final_path)
            print(f"Moved Folder from {scan_folder} to {final_path}")
        except OSError as e:
            print(f"ERROR moving completed scan, directory not empty. {e}")
            print("Continuing...")
    else:
        final_path = faileddir / scan_folder.stem
        final_path.mkdir(parents=True, exist_ok=True)
        try:
            scan_folder.rename(final_path)
            print(f"Moved Folder from {scan_folder} to {final_path}")
        except OSError as e:
            print(f"ERROR moving completed scan, directory not empty. {e}")
            print("Continuing...")

    execution_time = (time.time() - start_time) / 60
    logging.info(
        f",{date.today().strftime('%d-%m-%y')},{time.strftime('%H:%M')},{scan_folder.stem},{execution_time:.2f},{run.returncode}"
    )


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()
    completed_path = main_path / "completed_scans"
    failed_path = main_path / "failed_scans"
    main_dirs = [d for d in main_path.iterdir() if d.is_dir()]
    while len(main_dirs) > 2:
        print(f"Number of scans to process: {len(main_dirs)-2}")
        out_path = Path(dirs.out_dir).resolve()
        main_dirs.sort()
        p = mp.Pool(dirs.number)
        p.starmap(process_scan, zip(main_dirs, repeat(out_path), repeat(completed_path), repeat(failed_path)))
        p.close()
        p.join()

        main_dirs = [d for d in main_path.iterdir() if d.is_dir()]
    print("Finished Processing input directory")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "main_dir",
        type=str,
        help="Main folder containing repeat scans in subfolders.")
    parser.add_argument("out_dir", type=str, help="Output folder.")
    parser.add_argument("-n", "--number", type=int, default=8, help="Number of simultaneous Scans")
    args = parser.parse_args()
    log_name = datetime.now().strftime("airflow_log_%d_%m_%Y_%H_%M.log")
    logging.basicConfig(filename=log_name, filemode="a", level=logging.INFO)

    main(args)
