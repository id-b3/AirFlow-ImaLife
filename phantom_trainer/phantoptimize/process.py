import subprocess
from pathlib import Path

opfrnt_srpt = Path.resolve(Path("./scripts/opfront_phantom_single.sh"))
temp_out = Path.resolve(Path.joinpath(Path.cwd(), "./temp_run"))


# TODO: Create a function that runs one loop of phantom opfront and measuring. Returns an error measure.
def process_phantom(p_vol: str, p_seg: str, i_der: float = 0, o_der: float = 0, s_pen: float = 0) -> float:
    err_m = 0
    # 1. run opfront with parameters
    subprocess.run([str(opfrnt_srpt), str(Path.resolve(Path(p_vol))), str(Path.resolve(Path(p_seg))), str(temp_out),
                    f"-F {i_der} -G {o_der} -d {s_pen}"])
    # 2. split the airways
    # 3. measure the airways
    # 4. merge the airways
    # 5. calculate the error measure
    # return the error measure
    return err_m
