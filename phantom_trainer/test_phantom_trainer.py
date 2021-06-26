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
        in_der = trial.suggest_float('inner_derivative', -1, 1, step=0.01)
        out_der = trial.suggest_float('outer_derivative', -1, 1, step=0.01)
        error = trainer.process_phantom(trial.number, i_der=in_der, o_der=out_der, s_pen=0)

        return abs(error)

    study = optuna.create_study()
    study.optimize(objective, n_trials=20)
    print(study.best_trial)
    study.trials_dataframe().to_csv('trial_results.csv')


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
