import subprocess
import sys
from pathlib import Path
from .split.compute_boundbox_regions import comp_bound_box
from .split.split_segmentation_regions import split_seg_reg
from datetime import datetime
import logging
import pandas as pd
import numpy as np
from bronchipy.tree.airwaytree import AirwayTree
from bronchipy.io.branchio import save_summary_csv

# Script constants
opfront_script = str((Path(__file__).parent / "scripts" / "opfront_phantom_single.sh").resolve())
measure_split = str((Path(__file__).parent / "scripts" / "measure_phantom_single.sh").resolve())

# TODO: File constants - incorrect, have to obtain from the running process... in case the volume name is different.
p_surf_0 = "./phantom_volume_surface0.nii.gz"
p_surf_1 = "./phantom_volume_surface1.nii.gz"


class PhantomTrainer:
    def __init__(self, p_vol: str, p_seg: str, out_dir: str, log_lev: int = logging.DEBUG):
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

        self.volume = Path(p_vol).resolve()
        self.segmentation = str(Path(p_seg).resolve())
        self.out_dir = Path(out_dir).resolve()
        self.out_dir.mkdir(parents=True)
        (self.out_dir / "logs").mkdir()
        (self.out_dir / "common_files").mkdir()

        self.log_dir = str(self.out_dir / "logs" / f"training_log_{datetime.now()}.log")
        self.bound_box = str(self.out_dir / "common_files" / "boundboxes_split_regions_phantom.npy")

        # Compute and output the boundinx boxes for splitting.
        comp_bound_box(self.segmentation, self.bound_box)

        logging.basicConfig(level=log_lev, filename=self.log_dir)
        logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))

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
        run_out_dir = str(self.out_dir / f"run_{run_number}").replace('.', '-')

        logging.info(
            f"Starting Phantom {str(self.volume)} Training Run No.{run_number} with parameters:\n'{parameters}'\n"
            f"Outputdir {run_out_dir} \n"
            f"----------------------------------------------------------------\n")

        # 1. run opfront with parameters VOL SEG OUT_DIR OPFRONT_PARAMS
        logging.debug(f"Launching opfront for {str(self.volume)} number {run_number}...")
        subprocess.run([opfront_script, str(self.volume), self.segmentation, run_out_dir, parameters])

        # 2. split the airways
        logging.debug(f"Splitting results for opfront number {run_number}...")
        split_out_dir = split_seg_reg(run_out_dir, self.bound_box)
        logging.debug(f"Split phantom airways into {split_out_dir}...")

        # 3. measure the airways - iterate within the folders generated by split, output into same folder
        for split_path in Path(split_out_dir).iterdir():
            logging.debug(f"Measuring results for run {run_number} and {split_path.stem}...")
            inner_vol, outer_vol = self.get_split_vol(split_path)
            logging.debug(f"Split surface dirs are: \n"
                          f"{inner_vol}\n{outer_vol}")
            subprocess.run([measure_split, str(self.volume), inner_vol, outer_vol, str(split_path.resolve())])

        # 4. merge the airways
        logging.info(f"Merging results for run {run_number}...")

        list_inner = [str(list(split_path.glob("*_inner.csv"))[0])
                      for split_path in Path(split_out_dir).iterdir()]
        list_inner.sort()
        list_outer = [str(list(split_path.glob("*_outer.csv"))[0])
                      for split_path in Path(split_out_dir).iterdir()]
        list_outer.sort()
        list_local_inner = [str(list(split_path.glob("*_inner_local_pandas.csv"))[0])
                            for split_path in Path(split_out_dir).iterdir()]
        list_local_inner.sort()
        list_local_outer = [str(list(split_path.glob("*_outer_local_pandas.csv"))[0])
                            for split_path in Path(split_out_dir).iterdir()]
        list_local_outer.sort()
        list_branches = [str(list(split_path.glob("*_airways_centrelines.csv"))[0])
                         for split_path in Path(split_out_dir).iterdir()]
        list_branches.sort()

        logging.debug(f"List of files: Inner {list_inner}")
        logging.debug(f"List of files: Outer {list_outer}")
        logging.debug(f"List of files: Inner Local {list_local_inner}")
        logging.debug(f"List of files: Outer Local {list_local_outer}")
        logging.debug(f"List of files: Branches {list_branches}")

        combined_inner = pd.concat([pd.read_csv(f) for f in list_inner])
        combined_inner['branch'] = np.arange(1, len(combined_inner) + 1)
        combined_outer = pd.concat([pd.read_csv(f) for f in list_outer])
        combined_outer['branch'] = np.arange(1, len(combined_outer) + 1)
        combined_local_inner = pd.concat([pd.read_csv(f, delimiter=';') for f in list_local_inner])
        combined_local_inner['branch'] = np.arange(1, len(combined_local_inner) + 1)
        combined_local_outer = pd.concat([pd.read_csv(f, delimiter=';') for f in list_local_outer])
        combined_local_outer['branch'] = np.arange(1, len(combined_local_outer) + 1)
        combined_branches = pd.concat([pd.read_csv(f, delimiter=';') for f in list_branches])
        combined_branches['airway_id'] = np.arange(1, len(combined_branches) + 1)

        inner_file = f"{run_out_dir}/inner.csv"
        outer_file = f"{run_out_dir}/outer.csv"
        inner_local = f"{run_out_dir}/inner_local.csv"
        outer_local = f"{run_out_dir}/outer_local.csv"
        branch_file = f"{run_out_dir}/branches.csv"

        combined_inner.to_csv(inner_file, index=False)
        combined_outer.to_csv(outer_file, index=False)
        combined_local_inner.to_csv(inner_local, sep=";", index=False)
        combined_local_outer.to_csv(outer_local, sep=";", index=False)
        combined_branches.to_csv(branch_file, sep=";", index=False)

        # 6.  Process using airway analysis tools for summary.
        phantom = AirwayTree(branch_file=branch_file, inner_file=inner_file, outer_file=outer_file,
                             inner_radius_file=inner_local, outer_radius_file=outer_local, volume=self.volume)

        save_summary_csv(phantom.tree, f"{run_out_dir}/branch_summary.csv")

        # 5. Calculate the error measure
        logging.debug(f"Calculating error measure for run {run_number}...")
        err_inner = phantom.tree.inner_radius.mean() - (35.0/2/8)
        err_outer = phantom.tree.outer_radius.mean() - (48.6/2/8)
        logging.info(f"Inner error: {err_inner}")
        logging.info(f"Outer error: {err_outer}")
        err_m = (abs(err_inner) + abs(err_outer))/2

        # return the error measure
        logging.info(f"Error measure for {str(self.volume)} run No. {run_number} is: {err_m}")
        return err_m

    def get_split_vol(self, split_dir: Path) -> tuple:
        """
        Get the surface0 and surface1 paths from split code to feed into the measurement script.

        Parameters
        ----------
        split_dir: Path
            The directory path to the split phantom airway
        Returns
        -------
        Inner and outer surface paths as strings
        """
        # Create filepaths for the measure_phantom script to match the opfront_phantom script.
        root_out = split_dir / self.volume.stem.partition('.')[0]
        logging.debug(f"Getting surface filenames relative to split folder \n{root_out}")
        return str(Path(f"{root_out}_surface0.nii.gz").resolve()), str(Path(f"{root_out}_surface1.nii.gz").resolve())
