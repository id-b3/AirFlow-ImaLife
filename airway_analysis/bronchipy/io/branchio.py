import pandas as pd
from pathlib import Path


def load_brh_csv(in_file: str) -> pd.DataFrame:
    """

    @rtype: object
    """
    df = pd.read_csv(in_file, converters={'children': eval, 'point': eval}, delimiter=";")
    return df


def save_as_csv(dataframe: 'input dataframe', out_path: 'output path') -> None:
    parent_dir = Path(Path.cwd(), out_path).resolve()
    try:
        print(f"Saving {Path(out_path).stem} to {parent_dir}")
        dataframe.to_csv(parent_dir)
    except OSError as e:
        print(f"Creating folder {parent_dir}")
        print(f"Saving {Path(out_path).stem} to {parent_dir}")
        Path.mkdir(parent_dir.parent)
        dataframe.to_csv(parent_dir)
