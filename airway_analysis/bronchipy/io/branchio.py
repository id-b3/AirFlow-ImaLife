import pandas as pd
import os


def load_brh_csv(in_file: str) -> pd.Dataframe:
    df = pd.read_csv(in_file, converters={'children': eval, 'point': eval}, delimiter=";")
    return df


def save_as_csv(dataframe: 'input dataframe', out_path: 'output path') -> None:
    abs_dir = os.path.split(out_path)[0]
    if os.path.exists(abs_dir):
        os.mkdir(abs_dir)
        dataframe.save_csv(os.pathout_path)
