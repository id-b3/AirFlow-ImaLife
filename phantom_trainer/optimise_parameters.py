#!/usr/bin/env python
import datetime
import logging
import tempfile
from phantoptimize.phantomtrainer import PhantomTrainer
import argparse
import optuna


def main(infiles):

    trainer = PhantomTrainer(infiles.out_dir, log_lev=logging.INFO)

    def objective(trial):
        for p in infiles.param.split(","):
            if p == "o":
                param = trial.suggest_int(
                    f"parameter_o-i", infiles.min, infiles.max, step=infiles.step
                )
                trainer.param["o"] = param
                trainer.param["i"] = param
            elif p == "O":
                param = trial.suggest_int(
                    f"parameter_O-I", infiles.min, infiles.max, step=infiles.step
                )
                trainer.param["O"] = param
                trainer.param["I"] = param
            else:
                param = trial.suggest_float(
                    f"parameter_{p}", infiles.min, infiles.max, step=infiles.step
                )
                trainer.param[p] = param
        try:
            error_inner, error_outer, error_total = trainer.process_phantom(
                trial.number
            )
        except IndexError as e:
            logging.error(f"Run {trial.number} failed with error:\n {e}")
            if infiles.single:
                return 10
            else:
                return 10, 10
        if infiles.single:
            return error_total
        else:
            return error_inner, error_outer

    study = optuna.create_study(
        study_name=infiles.study_name, storage=f"sqlite:///{infiles.study_name}.db"
    )
    study.optimize(objective, n_trials=infiles.iter)
    study.trials_dataframe().to_csv(infiles.out_file)


if __name__ == "__main__":

    temp_out_folder = tempfile.TemporaryDirectory().name

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out_dir", type=str, help="Output directory", default=temp_out_folder
    )
    parser.add_argument(
        "--out_file",
        type=str,
        help="Output csv of the trials",
        default="trial_results.csv",
    )
    parser.add_argument(
        "--param",
        type=str,
        help="The parameters to optimise. Split with comma e.g. 'i,I,o,O' ",
        required=True,
    )
    parser.add_argument(
        "--min", type=float, help="Minimum inner derivative value", default=0
    )
    parser.add_argument(
        "--max", type=float, help="Maximum inner derivative value", default=10
    )
    parser.add_argument("--step", type=float, help="Step size", default=0.1)
    parser.add_argument("--iter", type=int, help="Number of iterations", default=20)
    parser.add_argument(
        "--single", type=bool, help="Use single error measure or separate", default=True
    )
    parser.add_argument(
        "--study_name",
        type=str,
        help="Name of this study",
        default=f"trial_{datetime.date.today()}",
    )
    print(f"Output to {temp_out_folder}")
    args = parser.parse_args()

    print("Print input arguments...")
    for key, value in vars(args).items():
        print("'%s' = %s" % (key, value))

    main(args)
