import subprocess
import sys
from pathlib import Path
from .split.calc_boundbox_regions import comp_bound_box
from .split.split_segmentation_regions import split_seg_reg
from datetime import datetime
import logging
import pandas as pd
import numpy as np
from bronchipy.tree.airwaytree import AirwayTree
from bronchipy.io.branchio import save_summary_csv

# Script constants
opfront_script = str((Path(__file__).parent / "scripts" / "opfront_phantom_complete.sh").resolve())


class PhantomTrainer:
    def __init__(self, out_dir: str, p_vol: str = "copdgene_phantom/phantom_volume.nii.gz",
                 p_seg: str = "copdgene_phantom/phantom_lumen.nii.gz",
                 p_seg_iso: str = "copdgene_phantom/phantom_lumen_iso_05.nii.gz", log_lev: int = logging.INFO):
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
        self.segmentation_iso = str(Path(p_seg_iso).resolve())
        self.out_dir = Path(out_dir).resolve()
        self.out_dir.mkdir(parents=True)
        (self.out_dir / "logs").mkdir()
        (self.out_dir / "common_files").mkdir()

        self.log_dir = str(self.out_dir / "logs" / f"training_log_{datetime.now()}.log")
        self.bound_box = str(self.out_dir / "common_files" / "boundboxes_split_regions_phantom.pkl")

        # Compute and output the boundinx boxes for splitting.
        logging.debug(f"Computing the bounding box based on the rescaled initial segmentation..."
                      f"\n Output to: {self.bound_box}")
        comp_bound_box(self.segmentation_iso, self.bound_box)

        logging.basicConfig(level=log_lev, filename=self.log_dir)

    # TODO: Create a function that runs one loop of phantom opfront and measuring. Returns an error measure.
    def process_phantom(self, run_number: int,
                        op_par: str = "-i 15 -o 15 -I 2 -O 2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0",
                        i_der: float = 0, o_der: float = 0, s_pen: float = 0) -> tuple:
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

        parameters = f"{op_par} -F {i_der:.2f} -G {o_der:0.2f} -d {s_pen:0.2f}"
        run_out_dir = str(self.out_dir / f"run_{run_number}").replace('.', '-')

        logging.info(
            f"Starting Phantom {str(self.volume)} Training Run No.{run_number} with parameters:\n'{parameters}'\n"
            f"Outputdir {run_out_dir} \n"
            f"----------------------------------------------------------------\n")

        # 1. run opfront with parameters VOL SEG OUT_DIR OPFRONT_PARAMS
        logging.debug(f"Launching opfront for {str(self.volume)} number {run_number}...")
        subprocess.run([opfront_script, str(self.volume), self.segmentation, self.bound_box, run_out_dir, parameters])

        # 5. merge the airways
        logging.info(f"Parsing results for run {run_number}...")

        inner_file = f"{run_out_dir}/phantom_lumen_inner.csv"
        outer_file = f"{run_out_dir}/phantom_lumen_outer.csv"
        inner_local = f"{run_out_dir}/phantom_lumen_inner_local_pandas.csv"
        outer_local = f"{run_out_dir}/phantom_lumen_outer_local_pandas.csv"
        branch_file = f"{run_out_dir}/phantom_lumen_airways_centrelines.csv"
        config = {'min_length': 1.0}

        # 6.  Process using airway analysis tools for summary.
        phantom = AirwayTree(branch_file=branch_file, inner_file=inner_file, outer_file=outer_file,
                             inner_radius_file=inner_local, outer_radius_file=outer_local,
                             volume=self.volume, config=config)

        save_summary_csv(phantom.tree, f"{run_out_dir}/branch_summary.csv")

        # 5. Calculate the error measure
        logging.debug(f"Calculating error measure for run {run_number}...")
        err_inner = phantom.tree.inner_radius.sum() - (35.0/2)
        err_outer = phantom.tree.outer_radius.sum() - (48.6/2)
        logging.info(f"Inner error: {err_inner}")
        logging.info(f"Outer error: {err_outer}")
        err_m = (abs(err_inner) + abs(err_outer))/2

        # return the error measure
        logging.info(f"Error measure for {str(self.volume)} run No. {run_number} is: {err_m}")
        return err_inner, err_outer, err_m
