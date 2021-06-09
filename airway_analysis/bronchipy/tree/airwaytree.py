import nibabel as nib
import pandas as pd
from functools import reduce
from math import pi, pow

from ..io import branchio as brio


class AirwayTree:

    def organise_tree(self) -> pd.DataFrame:
        """
        Takes the input files and combines them into a single merged dataframe.
        Calculates and inserts columns containing branch area data too.

        Returns
        -------
        A dataframe that is the merged combination of all csvs.
        """
        branch_df = brio.load_branch_csv(self.files['branch'])

        inner_df = brio.load_csv(self.files['inner'], True)
        inner_df.drop('generation', axis=1, inplace=True)
        # Calculate the area from the radius and insert as new row.
        inner_df['inner_area'] = inner_df.apply(lambda row: pow(row.inner_radius, 2) * pi, axis=1)
        inner_radius_df = brio.load_local_radius_csv(self.files['inner_rad'], True)

        outer_df = brio.load_csv(self.files['outer'], False)
        outer_df.drop('generation', axis=1, inplace=True)
        # Calculate the area from the radius and insert as new row.
        outer_df['outer_area'] = outer_df.apply(lambda row: pow(row.outer_radius, 2) * pi, axis=1)
        outer_radius_df = brio.load_local_radius_csv(self.files['outer_rad'], False)

        all_dfs = [branch_df, inner_df, inner_radius_df, outer_df, outer_radius_df]
        organised_tree = reduce(lambda left, right: pd.merge(left, right, on=['branch'], how='outer'), all_dfs)
        organised_tree.set_index('branch', inplace=True)
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

        '''
        The columns of the organised tree are:
        branch: int
            The branch ID
        generation: int
            The branch generation
        parent: int
            The branch ID of the Parent branch
        children: list[int]
            A list of branch IDs of the Children branches
        points: list[(Tuple)]
            A list of (x, y, z) tuples of branch points along centreline
        inner_radius: float
            The branch lumen global (summary) radius in mm
        inner_intensity: float
            The branch lumen global (summary) intensity in HU
        inner_samples: int
            Number of samples used for global measurement
        inner_area: float
            The global luminal area of the branch in mm^2
        inner_radii: list[float]
            A list of non-smoothed measurements of luminal local radii
        outer_radius: float
            The branch total branch thickness global (summary) radius in mm
        outer_intensity: float
            The branch total branch thickness global (summary) intensity in HU
        outer_samples: int
            Number of samples used for global measurement
        outer_area: float
            The branch global total branch area measurement in mm^2
        outer_radii: list[float]
            A list of non-smoothed measurements of total branch thickness local radii.
        '''
        self.tree = self.organise_tree()  #: Please see above for list of columns in airway tree dataframe.

    def get_airway_count(self) -> int:
        return self.tree.shape[0]
