#!/usr/bin/env python
import logging
import tempfile
from phantoptimize.phantomtrainer import PhantomTrainer
import argparse


def main(infiles):
    trainer = PhantomTrainer(infiles.in_volume, infiles.in_segment, infiles.out_dir, logging.INFO)
    trainer.process_phantom(1, i_der=-0.47, o_der=-0.51, s_pen=6.8)


if __name__ == '__main__':

    temp_out_folder = tempfile.TemporaryDirectory().name

    parser = argparse.ArgumentParser()
    parser.add_argument('--in_volume', type=str, help="Phantom Volume in nifti format.",
                        default="copdgene_phantom/phantom_volume.nii.gz")
    parser.add_argument('--in_segment', type=str, help="Phantom Segmentation in nifti format.",
                        default="copdgene_phantom/phantom_lumen.nii.gz")
    parser.add_argument('--out_dir', type=str, help="Output directory", default=temp_out_folder)
    print(f"Output to {temp_out_folder}")
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))

    main(args)
