import logging

from numpy import subtract, exp, negative, power, divide, convolve, sum, multiply
from numpy.linalg import norm
import numpy as np


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


def calc_smoothing(in_data: np.array, in_filter: np.array, is_padded: bool = True) -> np.array:
    """
    Apply smoothing to data by convolution with a filter

    Parameters
    ----------
    in_data: np.array
        Input data to be smoothed
    in_filter: np.array
        Smoothing filter
    is_padded: bool
        Option to add zero padding at the ends of input data, to have output data with same dimension as input
    Returns
    -------
    Data after smoothing
    """
    if len(in_data) < len(in_filter):
        logging.info(f"Size of input data {len(in_data)} smaller than filter window {len(in_filter)}.")
        return in_data

    if is_padded:
        return np.convolve(in_data, in_filter, 'same')
    else:
        return np.convolve(in_data, in_filter, 'valid')


def calc_smoothing_asAdria(in_data: np.array, in_filter: np.array, is_padded: bool = True) -> np.array:
    """
    Apply smoothing to data by convolution with a filter (same as Adria's implementation in MatLab code, for debugging)

    Parameters
    ----------
    in_data: np.array
        Input data to be smoothed
    in_filter: np.array
        Smoothing filter (from Adria's code: needs to contain odd num. elements)
    is_padded: bool
        Option to add zero padding at the ends of input data, to have output data with same dimension as input
    Returns
    -------
    Data after smoothing
    """

    # IMPORTANT: I think Adria's implementation is wrong, in the code to calculate convolved data with padding
    # IF THIS CONFIRMS: delete this function
    if len(in_data) < len(in_filter):
        logging.info(f"Size of input data {len(in_data)} smaller than filter window {len(in_filter)}.")
        return in_data

    length_filter = len(in_filter)
    middle_filter = int((length_filter + 1) / 2)

    out_data = np.convolve(in_data, in_filter, 'valid')

    if is_padded:
        num_data_padded = middle_filter - 1

        out_data_left_padded = np.zeros(num_data_padded)
        for i in range(num_data_padded):
            part_filter = in_filter[middle_filter - 1 - i:]
            part_filter = part_filter / np.sum(part_filter)     # I think this is wrong, I don't know why Adria does it
            part_data = in_data[:middle_filter + i]
            out_data_left_padded[i] = np.dot(part_data, part_filter)

        out_data_right_padded = np.zeros(num_data_padded)
        for i in range(num_data_padded):
            part_filter = in_filter[:middle_filter + i]
            part_filter = part_filter / np.sum(part_filter)     # I think this is wrong, I don't know why Adria does it
            part_data = in_data[-middle_filter - i:]
            out_data_right_padded[-i - 1] = np.dot(part_data, part_filter)

        out_data = np.concatenate((out_data_left_padded, out_data, out_data_right_padded))

    return out_data


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
