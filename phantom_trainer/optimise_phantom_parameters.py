from phantoptimize.phantomtrainer import PhantomTrainer

# 1. Set parameters
# 2. TODO Run trial.
# 3. Split


def main(agmts):
    trainer = PhantomTrainer('volume_in', 'segmentation_in', 'out_dir')
    error_margin = 0.1
    error = 1
    run_number = 1

    while abs(error) > error_margin:
        # TODO code to change the parameters
        error = trainer.process_phantom(run_number)
        run_number += 1
