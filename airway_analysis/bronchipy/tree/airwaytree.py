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
        # Load branches csv into dataframe
        branch_df = brio.load_branch_csv(self.files['branch'])
        # Apply the voxel dimensions to the points and create a data entry containing the centreline points in mm.
        branch_df['centreline'] = branch_df.apply(lambda row: [self.vox_to_mm(points) for points in row.points], axis=1)
        # Add entry describing the number of points in the airway measurement.
        branch_df['num_points'] = branch_df.apply(lambda row: len(row.points), axis=1)

        # Load inner measurements csvs into dataframes
        inner_df = brio.load_csv(self.files['inner'], True)
        inner_df.drop('generation', axis=1, inplace=True) # Redundant as branch_df already has generations
        # Calculate the area from the radius and insert as new column. Using pi*r^2
        inner_df['inner_area'] = inner_df.apply(lambda row: pow(row.inner_radius, 2) * pi, axis=1)
        inner_radius_df = brio.load_local_radius_csv(self.files['inner_rad'], True)

        # Load outer measurements csvr into dataframes
        outer_df = brio.load_csv(self.files['outer'], False)
        outer_df.drop('generation', axis=1, inplace=True)
        # Calculate the area from the radius and insert as new column.
        outer_df['outer_area'] = outer_df.apply(lambda row: pow(row.outer_radius, 2) * pi, axis=1)
        outer_radius_df = brio.load_local_radius_csv(self.files['outer_rad'], False)

        # Combine all the loaded data frames based on branches ID.
        all_dfs = [branch_df, inner_df, inner_radius_df, outer_df, outer_radius_df]
        organised_tree = reduce(lambda left, right: pd.merge(left, right, on=['branch'], how='outer'), all_dfs)
        organised_tree.set_index('branch', inplace=True)

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

        self.tree = self.organise_tree()  #: Please see above for list of columns in airway tree dataframe.

    def get_airway_count(self) -> int:
        """
        Method to return the number of branches in the airway tree.
        Returns
        -------
        Number of branches in airway tree.
        """
        return self.tree.shape[0]

    def vox_to_mm(self, point: tuple) -> tuple:
        """
        Takes a tuple x, y, z coordinate and applies the voxel dimensions to it.
        Parameters
        ----------
        point: tuple
            x, y, z co-ordinates

        Returns
        -------
        tuple
            x, y, z coordinates in millimeters
        """
        return point[0] * self.vol_vox_dims[0], point[1] * self.vol_vox_dims[1], point[2] * self.vol_vox_dims[2]

    def get_branch(self, branch_id: int) -> pd.Series:
        """

        Parameters
        ----------
        branch_id: int
            id value of the branch.

        Returns
        -------
        branch series

        See Also
        -------
        branch: The branch ID
        generation: The branch generation
        parent: The branch ID of the Parent branch
        children: list[int] A list of branch IDs of the Children branches
        points: list[(Tuple)] A list of (x, y, z) tuples of branch points along centreline in voxels (not in mm)
        centreline: list [(Tuple)] A list of (x, y, z) tuples of branch points along centreline in millimeters
        inner_radius: The branch lumen global (summary) radius in mm
        inner_intensity: The branch lumen global (summary) intensity in HU
        inner_samples: Number of samples used for global measurement
        inner_area: The global luminal area of the branch in mm^1
        inner_radii: list[float] A list of non-smoothed measurements of luminal local radii
        outer_radius: The branch total branch thickness global (summary) radius in mm
        outer_intensity: The branch total branch thickness global (summary) intensity in HU
        outer_samples: Number of samples used for global measurement
        outer_area: The branch global total branch area measurement in mm^1
        outer_radii: list[float] A list of non-smoothed measurements of total branch thickness local radii
        """
        try:
            return self.tree.loc[branch_id]
        except KeyError as e:
            print(f"No branch with id {e}.")
            return None
