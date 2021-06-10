from numpy.linalg import norm
from numpy import subtract


def calc_branch_length(points: list) -> float:
    """
    Calculates and sums the euclidian distance between all points along a branch centreline.

    Parameters
    -------
    points: list
        A list of tuples, which contain the x, y, z coordinates of the airways scaled to the voxel size (centreline)
    Returns
    -------
    Length of branch in millimeters
    """
    branch_length = 0

    for idx, point in enumerate(points[1:]):
        # print(f"Index {idx}. Distance between {points[idx]} and {point}")
        local_dist = norm(subtract(points[idx], point))
        branch_length += local_dist
        # print(f"Distance between points {local_dist: .3f}. Total distance {branch_length: .3f}")

    return branch_length
