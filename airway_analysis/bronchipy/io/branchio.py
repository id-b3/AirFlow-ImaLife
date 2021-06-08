import pandas as pd
from pathlib import Path


def load_brh_csv(in_file: str) -> pd.DataFrame:
    """
    Load the brh_translator csv file and return the DataFrame

    Parameters
    ----------
    in_file: str
        The output csv file from brh_translator using -pandas argument.

    Returns
    -------
    Branches dataframe sorted by branch id.
    """
    df = pd.read_csv(in_file, converters={'children': eval, 'point': eval}, delimiter=";")
    return df


def load_csv(in_file: str, inner: bool) -> pd.DataFrame:
    """
    Load the inner/outer csv file and return the DataFrame

    Parameters
    ----------
    inner: bool
        Whether the loaded file is for the inner surface. False if for outer.
    in_file: str
        The output csv file from gts_ray_measure.

    Returns
    -------
    Inner/outer dataframe sorted by branch ID
    """

    if inner:
        headers = ['branch', 'generation', 'inner_radius', 'inner_intensity', 'inner_samples']
    else:
        headers = ['branch', 'generation', 'outer_radius', 'outer_intensity', 'outer_samples']

    df = pd.read_csv(in_file, header=0, names=headers)
    return df


def load_local_radius_csv(in_file: str, inner: bool) -> pd.DataFrame:
    """
    Load the inner/outer_local_radius csv file and return the DataFrame

    Parameters
    ----------
    inner: bool
        Whether the input file is the inner local radius file. False if outer.
    in_file: str
        The output csv file from gts_ray_measure -l "local radius file"

    Returns
    -------
    Inner/Outer_local_radius dataframe sorted by branch ID
    """
    if inner:
        headers = ['branch', 'inner_radii']
    else:
        headers = ['branch', 'outer_radii']

    df = pd.read_csv(in_file, converters={'inner_radii': eval, 'outer_radii': eval}, header=0, names=headers, delimiter=";")

    return df


def save_as_csv(dataframe: 'input dataframe', out_path: 'output path' = "./airway_tree.csv") -> None:
    """
    Save the current airway tree dataframe as csv using pandas. Allows quicker loading and processing in the future.
    Parameters
    ----------
    dataframe: pandas.DataFrame
        The organised airways dataframe containing information from brh_translator and gts_ray_measure
    out_path: str
        The output file path.
    """
    parent_dir = Path(Path.cwd(), out_path).resolve()
    try:
        print(f"Saving {Path(out_path).stem} to {parent_dir}")
        dataframe.to_csv(parent_dir)
    except OSError as e:
        print(f"Creating folder {parent_dir}")
        print(f"Saving {Path(out_path).stem} to {parent_dir}")
        Path.mkdir(parent_dir.parent)
        dataframe.to_csv(parent_dir)
