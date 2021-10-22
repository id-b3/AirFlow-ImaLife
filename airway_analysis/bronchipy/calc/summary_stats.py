import pandas as pd


def param_by_gen(air_tree: pd.DataFrame, param: str) -> pd.DataFrame:

    return air_tree[[param, 'generation']].groupby('generation').describe()
