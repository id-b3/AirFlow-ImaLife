import subprocess
from pathlib import Path
from .split.split_segmentation_regions import split_seg_reg

opfrnt_srpt = Path.resolve(Path("./scripts/opfront_phantom_single.sh"))
temp_out = Path.resolve(Path.joinpath(Path.cwd(), "./temp_run"))
p_surf_0 = "./phantom_volume_surface0.nii.gz"
p_surf_1 = "./phantom_volume_surface1.nii.gz"


# TODO: Create a function that runs one loop of phantom opfront and measuring. Returns an error measure.
def process_phantom(p_vol: str, p_seg: str,
                    op_par: str = "-i 15 -o 15 -I 2 -O 2 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0",
                    i_der: float = 0, o_der: float = 0, s_pen: float = 0,
                    box_f: str = "./temp_run/boundboxes_split_regions_phantom.npy") -> float:
    err_m = 0
    # 1. run opfront with parameters VOL SEG OUT_DIR OPFRONT_PARAMS
    subprocess.run([str(opfrnt_srpt), str(Path.resolve(Path(p_vol))), str(Path.resolve(Path(p_seg))), str(temp_out),
                    f"{op_par} -F {i_der} -G {o_der} -d {s_pen}"])
    # 2. split the airways
    split_seg_reg(temp_out, box_f)
    # 3. measure the airways
    # 4. merge the airways
    # 5. calculate the error measure
    # return the error measure
    return err_m
