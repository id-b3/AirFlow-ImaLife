import logging

from numpy import subtract, exp, negative, power, divide, convolve, sum, multiply
from numpy.linalg import norm


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
        # logging.info(f"Index {idx}. Distance between {points[idx]} and {point}")
        local_dist = norm(subtract(points[idx], point))
        branch_length += local_dist
        # logging.info(f"Distance between points {local_dist: .3f}. Total distance {branch_length: .3f}")

    return branch_length


def calc_local_orientation() -> list:
    localorientation = []

    return localorientation


# TODO - port the local radii smoothing code.
def calc_smoothed_radius(radii: list, smo_filt: list) -> list:
    if len(radii) < len(smo_filt):
        logging.info(f"Number of radii {len(radii)} less than filter window {len(smo_filt)}.")
        return radii

    mid_index = int(len(smo_filt) / 2)
    left = []

    for i in range(0, mid_index - 2):
        tmp_filter = smo_filt[mid_index - i:]
        tmp_filter = divide(tmp_filter, sum(tmp_filter))
        left.append(sum(multiply(radii[:mid_index + i], tmp_filter)))

    middle = convolve(radii, smo_filt, 'valid')
    right

    return [left, middle, right]


def calc_tapering() -> list:
    tapering = []

    return tapering


def get_kernel(window_width: int, sigma: int) -> list:
    """
    Make a normalised Gaussian convolution kernel.

    Parameters
    -------
    window_width: int
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
