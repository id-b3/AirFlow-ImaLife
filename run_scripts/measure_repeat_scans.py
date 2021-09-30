from pathlib import Path
import subprocess
import argparse


def main(dirs):
    main_path = Path(dirs.main_dir).resolve()

    for directory in main_path.iterdir():
        for index, scan_dir in enumerate(directory.iterdir()):
            if index == 0:
                vol_name = f"{str(directory.stem)}_first.dcm"
            elif index == 1:
                vol_name = f"{str(directory.stem)}_repeat.dcm"
            else:
                print("Error processing scan, too many in folder.")
                continue
            outdir = Path(dirs.out_dir) / vol_name.removesuffix(".dcm") / "bronchial_parameters"
            outdir.mkdir(parents=True, exist_ok=True)

            for child in scan_dir.iterdir():
                print(child.absolute().resolve())
                input_folder = child.resolve()#).replace(' ', '\\ ')
                # input_folder += "/"

                # print(f"Processing scan {index} id {str(directory.stem)}, reconstruction {str(child.stem)}\n"
                #       f"input file {input_folder}\n"
                #       f"output folder... {outdir}")
                command_array = ["docker", "run", "--gpus", "all", "--rm", "-t", "--entrypoint",
                                 "scripts/run_local_machine.sh", "-v", f"{input_folder}:/input", "-v",
                                 f"{outdir}:/output", "airflow:repeat_scan", "/input", vol_name, "/output",
                                 f"/output/{vol_name}.log"]
                print(command_array)
                subprocess.run(command_array)

                # subprocess.run(["/bronchinet/scripts/run_local_machine.sh", f"{input_folder}",
                #                 f"{str(directory.stem)}_{index}.dcm", outdir, f"{main_path}/logfile.log"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("main_dir", type=str, help="Main folder containing repeat scans in subfolders.")
    parser.add_argument("out_dir", type=str, help="Output folder.")
    args = parser.parse_args()

    main(args)
