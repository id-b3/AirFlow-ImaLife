import phantoptimize.process as process_phantom

# 1. Set parameters
# 2. TODO Run trial.
# 3. Split

bound_box = "./temp_run/boundboxes_split_regions_phantom.npy"
opfront_params = "-i 15 -o 15 -I 2 -O 2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0"


def main(agmts):

    error_margin = 0.1
    error = 1

    while abs(error) > error_margin:
        # TODO code to change the parameters
        error = process_phantom()
