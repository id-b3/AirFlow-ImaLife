#!/usr/bin/env python
import logging
import tempfile
from phantoptimize.phantomtrainer import PhantomTrainer
import argparse
import optuna


def main(infiles):

    trainer = PhantomTrainer(infiles.in_volume, infiles.in_segment, infiles.out_dir, logging.INFO)
    logging.getLogger().setLevel(logging.INFO)

    def objective(trial):
        in_der = trial.suggest_float('inner_derivative', infiles.inner_min, infiles.inner_max, step=infiles.step)
        out_der = trial.suggest_float('outer_derivative', infiles.outer_min, infiles.outer_max, step=infiles.step)
        try:
            error_inner, error_outer, error_total = trainer.process_phantom(trial.number, i_der=in_der, o_der=out_der,
                                                                            s_pen=infiles.sep)
        except IndexError as e:
            logging.error(f"Run {trial.number} failed with error:\n {e}")
            return 10, 10

        return error_inner, error_outer

    study = optuna.create_study(directions=["minimize", "minimize"])
    study.optimize(objective, n_trials=infiles.iter)
    study.trials_dataframe().to_csv('trial_results.csv')


if __name__ == '__main__':

    temp_out_folder = tempfile.TemporaryDirectory().name

    parser = argparse.ArgumentParser()
    parser.add_argument('--in_volume', type=str, help="Phantom Volume in nifti format.",
                        default="copdgene_phantom/phantom_volume.nii.gz")
    parser.add_argument('--in_segment', type=str, help="Phantom Segmentation in nifti format.",
                        default="copdgene_phantom/phantom_lumen.nii.gz")
    parser.add_argument('--out_dir', type=str, help="Output directory", default=temp_out_folder)
    parser.add_argument('--out_file', type=str, help="Output csv of the trials", default="trial_results.csv")
    parser.add_argument('--inner_min', type=float, help="Minimum inner derivative value", default=-0.6)
    parser.add_argument('--inner_max', type=float, help="Maximum inner derivative value", default=-0.1)
    parser.add_argument('--outer_min', type=float, help="Minimum outer derivative value", default=-1.1)
    parser.add_argument('--outer_max', type=float, help="Maximum outer derivative value", default=-0.5)
    parser.add_argument('--step', type=float, help="Step size", default=0.02)
    parser.add_argument('--sep', type=float, help="Separation penalty", default=0)
    parser.add_argument('--iter', type=int, help="Number of iterations", default=10)
    print(f"Output to {temp_out_folder}")
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("\'%s\' = %s" % (key, value))

    main(args)
