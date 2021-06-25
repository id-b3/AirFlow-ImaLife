import subprocess
from pathlib import Path
from .split.compute_boundbox_regions import comp_bound_box
from .split.split_segmentation_regions import split_seg_reg
from datetime import datetime
import logging

# Script constants
opfront_script = str(Path("./scripts/opfront_phantom_single.sh").resolve())
measure_split = str(Path("./scripts/measure_phantom_single.sh").resolve())

# TODO: File constants - incorrect, have to obtain from the running process... in case the volume name is different.
p_surf_0 = "./phantom_volume_surface0.nii.gz"
p_surf_1 = "./phantom_volume_surface1.nii.gz"


class PhantomTrainer:
    def __init__(self, p_vol: str, p_seg: str, out_dir: str):
        """
        Phantom Trainer class. Contains the information to repeatedly run the process_phantom method, which calculates
        an error meaasure for a given set of parameters.

        Parameters
        ----------
        p_vol: str
            Phantom volume file
        p_seg: str
            Phantom segmentation file
        out_dir: str
            Output Directory for this training run.
        """

        self.volume = str(Path(p_vol).resolve())
        self.segmentation = str(Path(p_seg).resolve())
        self.out_dir = Path(out_dir).resolve()
        self.log_dir = str(self.out_dir / "logs" / f"training_log_{datetime.now()}.log")
        self.bound_box = str(self.out_dir / "common_files" / "boundboxes_split_regions_phantom.npy")

        # Compute and output the boundinx boxes for splitting.
        comp_bound_box(self.segmentation, self.bound_box)

        logging.basicConfig(level=logging.DEBUG, filename=self.log_dir)

    # TODO: Create a function that runs one loop of phantom opfront and measuring. Returns an error measure.
    def process_phantom(self, run_number: int,
                        op_par: str = "-i 15 -o 15 -I 2 -O 2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0",
                        i_der: float = 0, o_der: float = 0, s_pen: float = 0) -> float:
        """
        A method that processes the phantom and calculates an error measure.

        Parameters
        ----------
        run_number: int
            The number of the current run.
        op_par: str
            Opfront Parameters
        i_der: float
            Inner derivative - test variable (range -1 to 1)
        o_der: float
            Outer derivative - test variable (range -1 to 1)
        s_pen: float
            Separation penalty - test variable (range 0 to 10)

        Returns
        -------
        The error measure for this set of opfront parameters.
        """

        err_m = 1  #: The error measure. Initialised to 1
        parameters = f"{op_par} -F {i_der} -G {o_der} -d {s_pen}"
        run_out_dir = str(self.out_dir / f"run_{run_number}_F{i_der}G{o_der}d{s_pen}")  #: Dir for current run output

        logging.info(f"Starting Phantom {self.volume} Training Run No.{run_number} with parameters '{parameters}'\n"
                     f"Outputdir {run_out_dir} \n"
                     f"----------------------------------------------------------------\n")

        # 1. run opfront with parameters VOL SEG OUT_DIR OPFRONT_PARAMS
        logging.debug(f"Launching opfront for {self.volume} number {run_number}...")
        subprocess.run([opfront_script, self.volume, self.segmentation, run_out_dir])

        # 2. split the airways
        if not Path.exists(Path()):
            logging.debug(f"No bounding box found, computing bounding-box regions for run {run_number}...")
            comp_bound_box(self.segmentation, "./common_run/boundboxes_split_regions_phantom.npy")

        logging.debug(f"Splitting results for opfront number {run_number}...")
        split_seg_reg()
        # 3. measure the airways
        logging.debug(f"Measuring results for run {run_number}...")
        subprocess.run([measure_split, "VOL", "INNER_SURF", "OUTER_SURF", "OUT_FOLDER"])  # TODO CHANGE PLACEHOLDER INPUTS
        # 4. merge the airways
        logging.debug(f"Merging results for run {run_number}...")
        # 5. calculate the error measure
        logging.debug(f"Calculating error measure for run {run_number}...")
        # return the error measure
        logging.info(f"Error measure for {self.volume} run No. {run_number} is: {err_m}")
        return err_m
