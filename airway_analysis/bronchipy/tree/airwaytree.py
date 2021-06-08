import nibabel
import nibabel as nib
import pandas as pd

from ..io import branchio as brio


class Branch:
    def __init__(self, info_list: list):

        self.index = info_list[0]
        self.parent = info_list[1]
        self.children = info_list[2]
        self.points = info_list[3]
        self.generation = info_list[4]


def organise_tree(branches: str, inner_file: str, inner_radius_file: str, outer_file: str, outer_radius_file: str,
                  voxel_dims: list, config_file: dict) -> pd.DataFrame:
    """
    This function combines the outputs of various opfront results files into one data-frame, organised by the airway id.

    Parameters
    ----------
    branches: str
        file containing the branch info from brh_translate (.csv obtained with -pandas option)
    inner_file: str
        file _inner.csv
    inner_radius_file: str
        file _inner_local_radius.csv
    outer_file: str
        file _outer.csv
    outer_radius_file: str
        file _outer_local_radius.csv
    voxel_dims: list
        a list of voxel dimensions of the volume [x,y,z,t]
    config_file: dict
        dictionary containing the configuration parameters

    Returns
    -------
    organisedTree: pandas.DataFrame()
        organised and concatenated dataframe containing all the branches and their relevant information
    """

    branch_df = brio.load_brh_csv(branches)

    inner_df = brio.load_csv(inner_file)
    inner_radius_df = brio.load_local_radius_csv(inner_radius_file)

    outer_df = brio.load_csv(outer_file)
    outer_radius_df = brio.load_local_radius_csv(outer_radius_file)

    print("Merging inner and inner local radius...")
    organisedtreeinner = pd.merge(inner_df, inner_radius_df, how='outer', on='branch')
    print("Merging outer and outer local radius...")
    organisedtreeouter = pd.merge(inner_df, inner_radius_df, how='outer', on='branch')
    print("Merging branches...")
    organisedtreetotal = pd.merge(organisedtreeinner, organisedtreeouter, how='outer', on='branch')
    organisedtreetotal = pd.merge(organisedtreetotal, branch_df, how='outer', on='branch')

    return organisedtreetotal


class AirwayTree:

    def __init__(self, branch_file: str, inner_file: str, inner_radius_file: str, outer_file: str,
                 outer_radius_file: str, config_file: str, volume: str) -> object:
        """

        Parameters
        ----------
        branch_file: str
        inner_file: str
        inner_radius_file: str
        outer_file: str
        outer_radius_file: str
        config_file: str
        volume: str

        Returns
        ----------
        AirwayTree Object containing volume information and the airway tree data.
        """
        vol_header = nib.load(volume).header
        self.vol_dims = vol_header.get_data_shape()
        self.vol_vox_dims = vol_header.get_zooms()

        self.tree = organise_tree(branches=branch_file, inner_file=inner_file, inner_radius_file=inner_radius_file,
                                  outer_file=outer_file, outer_radius_file=outer_radius_file,
                                  voxel_dims=self.vol_vox_dims, config_file=config_file)

    def get_airway_count(self) -> int:
        return self.tree.shape[0]
