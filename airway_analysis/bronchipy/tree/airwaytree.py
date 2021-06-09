import nibabel as nib
import pandas as pd
from functools import reduce

from ..io import branchio as brio


class Branch:
    def __init__(self, info_list: list):
        self.index = info_list[0]
        self.parent = info_list[1]
        self.children = info_list[2]
        self.points = info_list[3]
        self.generation = info_list[4]


class AirwayTree:

    def organise_tree(self) -> pd.DataFrame:
        """
        Takes the input files and combines them into a single merged dataframe.

        Returns
        -------
        A dataframe that is the merged combination of all csvs.
        """
        branch_df = brio.load_branch_csv(self.files['branch'])

        inner_df = brio.load_csv(self.files['inner'], True)
        inner_df.drop('generation', axis=1, inplace=True)
        inner_radius_df = brio.load_local_radius_csv(self.files['inner_rad'], True)

        outer_df = brio.load_csv(self.files['outer'], False)
        outer_df.drop('generation', axis=1, inplace=True)
        outer_radius_df = brio.load_local_radius_csv(self.files['outer_rad'], False)

        all_dfs = [branch_df, inner_df, inner_radius_df, outer_df, outer_radius_df]
        organised_tree = reduce(lambda left, right: pd.merge(left, right, on=['branch'], how='outer'), all_dfs)
        # organised_tree = organised_tree.loc[:, ~organised_tree.columns.duplicated()]

        return organised_tree

    def __init__(self, branch_file: str, inner_file: str, inner_radius_file: str, outer_file: str,
                 outer_radius_file: str, volume: str):
        """

        Parameters
        ----------
        branch_file: str
        inner_file: str
        inner_radius_file: str
        outer_file: str
        outer_radius_file: str
        volume: str

        Returns
        ----------
        AirwayTree Object containing volume information and the airway tree data.
        """
        self.files = {'branch': branch_file, 'inner': inner_file, 'inner_rad': inner_radius_file, 'outer': outer_file,
                      'outer_rad': outer_radius_file, 'vol': volume}

        vol_header = nib.load(volume).header
        self.vol_dims = vol_header.get_data_shape()
        self.vol_vox_dims = vol_header.get_zooms()
        self.tree = self.organise_tree()

    def get_airway_count(self) -> int:
        return self.tree.shape[0]
