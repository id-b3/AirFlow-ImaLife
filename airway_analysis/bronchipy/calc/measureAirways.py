from numpy.linalg import norm
from numpy import subtract, exp, negative, power, divide


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


def calc_local_orientation() -> list:
    localorientation = []

    return localorientation


def calc_smoothed_radius(radii: list, smo_filt: dict) -> list:
    smo_rad_l = 0
    smo_rad_r = 0
    smo_rad_m = 0

    return [smo_rad_l, smo_rad_m, smo_rad_r]


def calc_tapering() -> list:
    tapering = []

    return tapering


def get_kernel(window_width: list, sigma: int) -> list:
    """
    Parameters
    -------
    window_width: list
        List of intervals for gaussian window
    sigma: int
        Standard deviation or "width" of gaussian curve
    Returns
    -------
    normalised kernel of gaussian window
    """
    x = [*range(-window_width, window_width + 1)]
    kernel = exp(divide(power(negative(x), 2), 2 * power(sigma, 2)))
    kernel = kernel / sum(kernel)

    return kernel
