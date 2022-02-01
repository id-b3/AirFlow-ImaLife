from pathlib import Path
import subprocess
import argparse
import logging
import time
from datetime import date
import multiprocessing


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()

    for directory in main_path.iterdir():
        for index, scan_dir in enumerate(directory.iterdir()):
            if index == 0:
                vol_name = f"{str(directory.stem)}_repeat.dcm"
            elif index == 1:
                vol_name = f"{str(directory.stem)}_first.dcm"
            else:
                logging.error("Error processing scan, too many in folder.")
                continue
            outdir = Path(dirs.out_dir) / directory.stem / vol_name.removesuffix(".dcm")
            outdir.mkdir(parents=True, exist_ok=True)

            for child in scan_dir.iterdir():
                logging.debug(child.absolute().resolve())
                input_folder = child.resolve()

                command_array = [
                    "docker",
                    "run",
                    "--gpus",
                    "all",
                    "--rm",
                    "-t",
                    "--entrypoint",
                    "scripts/run_local_machine_for_repeat.sh",
                    "-v",
                    f"{input_folder}:/input",
                    "-v",
                    f"{outdir}:/output",
                    "airflow:repeat_scan",
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
                    f",{date.today().strftime('%d-%m-%y')},{str(directory.stem)},{run.returncode},{execution_time:.2f}"
                )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "main_dir", type=str, help="Main folder containing repeat scans in subfolders."
    )
    parser.add_argument("out_dir", type=str, help="Output folder.")
    args = parser.parse_args()

    logging.basicConfig(filename=f"latest_run.log", filemode="a", level=logging.INFO)

    main(args)
