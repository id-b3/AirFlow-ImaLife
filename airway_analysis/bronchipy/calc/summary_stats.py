import pandas as pd


def param_by_gen(air_tree: pd.DataFrame, gen: int, param: str) -> float:
    """

    Parameters
    ----------
    param    : parameter to summarise
    gen      : generation to summarise
    air_tree : pandas dataframe
    """
    return air_tree.groupby("generation")[param].describe().at[gen, "mean"]
    # return air_tree[[param, "generation"]].groupby("generation").describe().at[gen, "mean"]


def agg_param(tree: pd.DataFrame, gens: list, param: str) -> float:
    """

    Parameters
    ----------
    tree
    gens
    param
    """

    return tree[(tree.generation >= gens[0]) & (tree.generation <= gens[1])][param].mean()


def total_count(tree: pd.DataFrame) -> int:
    return tree.index.max()
