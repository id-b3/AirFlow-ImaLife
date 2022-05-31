from pathlib import Path
import subprocess
import argparse
import logging
import time
from datetime import date, datetime
from multiprocessing import Pool


def process_scan(scan_folder, outdir, vol_name, timer):

    docker_name = "colossali/airflow:eureka_1.1"
    outdir.mkdir(parents=True, exist_ok=True)
    for child in scan_folder.iterdir():
        logging.debug(child.absolute().resolve())
        input_folder = child.resolve()

        command_array = [
            "docker",
            "run",
            "--gpus",
            "all",
            "--rm",
            "-t",
            "-v",
            f"{input_folder}:/input",
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
        time.sleep(timer)
        run = subprocess.run(command_array)
        execution_time = (time.time() - start_time) / 60
        logging.info(
            f",{date.today().strftime('%d-%m-%y')},{time.strftime('%H:%M')},{vol_name},{run.returncode},{execution_time:.2f}"
        )


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()
    main_dirs = [f for f in main_path.iterdir() if f.is_dir()]
    main_dirs.sort()
    iter_dir = iter(main_dirs)
    timers = [0, 15, 30, 45, 60, 75, 90, 105]
    for dir1 in iter_dir:
        dir2 = next(iter_dir)
        dir3 = next(iter_dir)
        dir4 = next(iter_dir)
        scan_dirs = [f for f in dir1.iterdir() if f.is_dir()]
        scan_dirs2 = [f for f in dir2.iterdir() if f.is_dir]
        scan_dirs3 = [f for f in dir3.iterdir() if f.is_dir]
        scan_dirs4 = [f for f in dir4.iterdir() if f.is_dir]
        scan_dirs.extend(scan_dirs2)
        scan_dirs.extend(scan_dirs3)
        scan_dirs.extend(scan_dirs4)

        vol_names = [
            f"{str(dir1.stem)}_repeat.dcm",
            f"{str(dir1.stem)}_first.dcm",
            f"{str(dir2.stem)}_repeat.dcm",
            f"{str(dir2.stem)}_first.dcm",
            f"{str(dir3.stem)}_repeat.dcm",
            f"{str(dir3.stem)}_first.dcm",
            f"{str(dir4.stem)}_repeat.dcm",
            f"{str(dir4.stem)}_first.dcm",
        ]

        outdirs = [
            Path(dirs.out_dir) / dir1.stem / vol_names[0].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir1.stem / vol_names[1].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir2.stem / vol_names[2].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir2.stem / vol_names[3].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir3.stem / vol_names[4].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir3.stem / vol_names[5].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir4.stem / vol_names[6].removesuffix(".dcm"),
            Path(dirs.out_dir) / dir4.stem / vol_names[7].removesuffix(".dcm"),
        ]

        pool = Pool(8)
        pool.starmap(process_scan, zip(scan_dirs, outdirs, vol_names, timers))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "main_dir", type=str, help="Main folder containing repeat scans in subfolders."
    )
    parser.add_argument("out_dir", type=str, help="Output folder.")
    args = parser.parse_args()
    log_name = datetime.now().strftime("airflow_log_%H_%M_%d_%m_%Y.log")
    logging.basicConfig(filename=log_name, filemode="a", level=logging.INFO)

    main(args)
