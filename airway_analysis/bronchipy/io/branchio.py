from pathlib import Path
import pandas as pd
import logging


def load_branch_csv(in_file: str) -> pd.DataFrame:
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
    logging.info(f"Loading branch csv {in_file}...")
    headers = ["branch", "generation", "parent", "children", "points"]
    df = pd.read_csv(
        in_file,
        header=0,
        names=headers,
        converters={"children": eval, "points": eval},
        delimiter=";",
    )
    logging.info("Success!")
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

    logging.info(f"Loading global csv {in_file}...")
    if inner:
        headers = [
            "branch",
            "generation",
            "inner_radius",
            "inner_intensity",
            "inner_samples",
        ]
    else:
        headers = [
            "branch",
            "generation",
            "outer_radius",
            "outer_intensity",
            "outer_samples",
        ]

    df = pd.read_csv(in_file, header=0, names=headers)
    logging.info("Success!")
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

    logging.info(f"Loading local csv {in_file}...")
    if inner:
        headers = ["branch", "inner_radii"]
    else:
        headers = ["branch", "outer_radii"]

    df = pd.read_csv(
        in_file,
        converters={"inner_radii": eval, "outer_radii": eval},
        header=0,
        names=headers,
        delimiter=";",
    )
    logging.info("Success!")
    return df


def save_as_csv(dataframe: pd.DataFrame, out_path: str = "./airway_tree.csv") -> None:
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
        logging.info(f"Saving {Path(out_path).stem} to {parent_dir}")
        dataframe.to_csv(parent_dir, sep=";")
    except OSError:
        logging.info(f"Creating folder {parent_dir}")
        logging.info(f"Saving {Path(out_path).stem} to {parent_dir}")
        Path.mkdir(parent_dir.parent)
        dataframe.to_csv(parent_dir)


def load_tree_csv(tree_csv: str) -> pd.DataFrame:
    """
    Loads and evaluates cells in the airway data csv.
    Parameters
    ----------
    tree_csv: str
        File path to the airway tree csv

    Returns
    -------
    Airway Tree Dataframe
    """

    try:
        df = pd.read_csv(
            tree_csv,
            delimiter=";",
            converters={
                "children": eval,
                "points": eval,
                "centreline": eval,
                "inner_radii": eval,
                "outer_radii": eval,
            },
        )
        return df
    except IOError:
        logging.error("Error loading the airway tree csv.")


def save_summary_csv(tree: pd.DataFrame, filename: str = "./airway_summary.csv"):
    """
    Saves a summary CSV with bronchial parameters per branch.

    Parameters
    ----------
    tree: pandas.DataFrame
        The input airway tree dataframe
    filename: str
        The output filepath
    """
    save_path = Path(filename).resolve()
    parent_path = save_path.parent
    logging.info(f"Saving summary to {save_path}")
    if not Path.exists(parent_path):
        Path.mkdir(parent_path)
    tree_sum = tree[
        [
            "generation",
            "parent",
            "length",
            "inner_radius",
            "inner_intensity",
            "inner_global_area",
            "outer_radius",
            "outer_intensity",
            "wall_global_area",
            "wall_global_area_perc",
            "wall_global_thickness",
            "wall_global_thickness_perc",
            "lumen_tapering",
            "lumen_tapering_perc",
            "x",
            "y",
            "z",
        ]
    ]
    if "lobes" in tree.columns:
        tree_sum["lobes"] = tree["lobes"]
    tree_sum.to_csv(save_path)


def save_pickle_tree(dataframe: pd.DataFrame, savepath: str = "./airway_tree.pickle"):
    try:
        dataframe.to_pickle(savepath)
    except IOError as e:
        logging.error(f"Error saving airway tree to pickle: {e}")


def load_pickle_tree(loadpath: str = "./airway_tree.pickle") -> pd.DataFrame:
    try:
        return pd.read_pickle(loadpath)
    except FileNotFoundError as e:
        logging.error(
            f"Loading airway tree from pickle failed. File {e.filename} not found."
        )
