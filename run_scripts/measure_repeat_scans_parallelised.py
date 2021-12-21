from pathlib import Path
import subprocess
import argparse
import logging
import time
from datetime import date
from multiprocessing import Pool


# def process_main(directory, sleep):
#     scan_dirs = [f for f in directory.iterdir() if f.is_dir()]
#     scan_dirs.sort()
#     vol_names = [f"{str(directory.stem)}_repeat.dcm", f"{str(directory.stem)}_first.dcm"]
#     outdirs = [Path(dirs.out_dir) / directory.stem / vol_names[0].removesuffix(".dcm"),
#                Path(dirs.out_dir) / directory.stem / vol_names[1].removesuffix(".dcm")]
#     timers = [1, 120]
#     time.sleep(sleep)
#     pool = Pool(2)
#     pool.starmap(process_scan, zip(scan_dirs, outdirs, vol_names, timers))
#     pass
#

def process_scan(scan_folder, outdir, vol_name, sleep):
    outdir.mkdir(parents=True, exist_ok=True)
    for child in scan_folder.iterdir():
        logging.debug(child.absolute().resolve())
        input_folder = child.resolve()

        command_array = ["docker", "run", "--gpus", "all", "--rm", "-t", "--entrypoint",
                         "scripts/run_local_machine_for_repeat.sh", "-v", f"{input_folder}:/input", "-v",
                         f"{outdir}:/output", "airflow:repeat_scan", "/input", vol_name, "/output",
                         f"/output/{vol_name}.log"]

        logging.debug(command_array)
        start_time = time.time()
        time.sleep(sleep)
        run = subprocess.run(command_array)
        execution_time = (time.time() - start_time)/60
        logging.info(f",{date.today().strftime('%d-%m-%y')},{vol_name},{run.returncode},{execution_time:.2f}")


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()
    # main_dirs = [f for f in main_path.iterdir() if f.is_dir()]
    # main_dirs.sort()
    # iter_dir = iter(main_dirs)
    #
    # for dir1 in iter_dir:
    #     dir2 = next(iter_dir)
    #     scan_dirs = [f for f in dir1.iterdir() if f.is_dir()]
    #     scan_dirs2 = [f2 for f2 in dir2.iterdir() if f2.is_dir]
    #     scan_dirs.extend(scan_dirs2)
    #     vol_names = [f"{str(dir1.stem)}_repeat.dcm", f"{str(dir1.stem)}_first.dcm",
    #                  f"{str(dir2.stem)}_repeat.dcm", f"{str(dir2.stem)}_first.dcm"]
    #     outdirs = [Path(dirs.out_dir) / dir1.stem / vol_names[0].removesuffix(".dcm"), Path(dirs.out_dir) / dir1.stem / vol_names[1].removesuffix(".dcm"),
    #                Path(dirs.out_dir) / dir2.stem / vol_names[2].removesuffix(".dcm"), Path(dirs.out_dir) / dir2.stem / vol_names[3].removesuffix(".dcm")]
    #     timers = [1, 150, 300, 450]
    #     pool = Pool(4)
    #     pool.starmap(process_scan, zip(scan_dirs, outdirs, vol_names, timers))

    for directory in main_path.iterdir():
        scan_dirs = [f for f in directory.iterdir() if f.is_dir()]
        scan_dirs.sort()
        vol_names = [f"{str(directory.stem)}_repeat.dcm", f"{str(directory.stem)}_first.dcm"]
        outdirs = [Path(dirs.out_dir) / directory.stem / vol_names[0].removesuffix(".dcm"), Path(dirs.out_dir) / directory.stem / vol_names[1].removesuffix(".dcm")]
        timers = [1, 120]
        pool = Pool(2)
        pool.starmap(process_scan, zip(scan_dirs, outdirs, vol_names, timers))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("main_dir", type=str, help="Main folder containing repeat scans in subfolders.")
    parser.add_argument("out_dir", type=str, help="Output folder.")
    args = parser.parse_args()

    logging.basicConfig(filename=f"latest_parallel_run.log", filemode='a', level=logging.INFO)

    main(args)
