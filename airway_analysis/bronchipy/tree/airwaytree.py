import nibabel as nib


class Branch:
    def __init__(self, info_list: list):
        self.index = info_list[0]
        self.parent = info_list[1]
        self.children = info_list[2]
        self.points = info_list[3]
        self.generation = info_list[4]


class AirwayTree:
    def __init__(self, branches: 'Branches pandas file', volume: 'Nifti main volume'):
        self.branches = brio.load_brh_csv(branches)
        vol_header = nib.load(volume).header
        self.vol_dims = vol_header.get_data_shape()
        self.vol_pix_dims = vol_header.get_zooms()

    def get_branch(self, branch_index: int) -> Branch:
        info_list = self.branches[branch_index]
        return Branch(info_list)

    def get_airway_count(self) -> int:
        return self.branches.shape[0]
