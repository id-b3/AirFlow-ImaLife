import subprocess
from pathlib import Path
from .split.split_segmentation_regions import split_seg_reg
import tempfile
import logging

opfrnt_spt = Path.resolve(Path("./scripts/opfront_phantom_single.sh"))
measre_spt = Path.resolve(Path("./scripts/measure_phantom_single.sh"))
temp_out = tempfile.TemporaryDirectory()
log_out = Path.resolve(Path("../phantom_logs/"))
p_surf_0 = "./phantom_volume_surface0.nii.gz"
p_surf_1 = "./phantom_volume_surface1.nii.gz"


# TODO: Create a function that runs one loop of phantom opfront and measuring. Returns an error measure.
def process_phantom(proc_run: int, p_vol: str, p_seg: str,
                    op_par: str = "-i 15 -o 15 -I 2 -O 2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0",
                    i_der: float = 0, o_der: float = 0, s_pen: float = 0,
                    box_f: str = "./temp_run/boundboxes_split_regions_phantom.npy") -> float:

    parameters = f"{op_par} -F {i_der} -G {o_der} -d {s_pen}"
    logging.info(f"Starting Phantom {p_vol} Training Run No.{proc_run} with parameters '{parameters}'\n"
                 f"----------------------------------------------------------------\n")
    err_m = 0

    # 1. run opfront with parameters VOL SEG OUT_DIR OPFRONT_PARAMS
    logging.debug(f"Launching opfront for {p_vol} number {proc_run}...")
    subprocess.run([str(opfrnt_spt), str(Path.resolve(Path(p_vol))),
                    str(Path.resolve(Path(p_seg))), str(temp_out), parameters])
    # 2. split the airways
    logging.debug(f"Splitting results for opfront number {proc_run}...")
    split_seg_reg(str(temp_out), box_f)
    # 3. measure the airways
    logging.debug(f"Measuring results for run {proc_run}...")
    subprocess.run([str(measre_spt), "VOL", "INNER_SURF", "OUTER_SURF", "OUT_FOLDER"])  # TODO CHANGE PLACEHOLDER INPUTS
    # 4. merge the airways
    logging.debug(f"Merging results for run {proc_run}...")
    # 5. calculate the error measure
    logging.debug(f"Calculating error measure for run {proc_run}...")
    # return the error measure
    logging.info(f"Error measure for {p_vol} run No. {proc_run} is: {err_m}")
    return err_m
