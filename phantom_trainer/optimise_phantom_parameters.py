from phantoptimize.split.compute_boundbox_regions import comp_bound_box

# 1. Set parameters
# 2. TODO Run trial.
# 3. Split

bound_box = "./temp_run/boundboxes_split_regions_phantom.npy"
opfront_params = "-i 15 -o 15 -I 2 -O 2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0"


def main(agmts):
    comp_bound_box(agmts.init_seg, bound_box)
