import logging
import numpy as np
from scipy.spatial import distance


def calc_branch_length(points: list) -> float:
    """
    Calculates and sums the euclidian distance between all points along a branch centreline.

    Parameters
    -------
    points: np.array
        List of centerline points (x, y, z coordinates of the airways scaled to the voxel size (centreline))
    Returns
    -------
    Length of branch in millimeters
    """
    branch_length = 0

    points_arr = np.array(points)
    num_points = points_arr.shape[0]
    logging.debug(f"Number of points loaded {num_points}")

    for i in range(1, num_points):
        local_dist = np.linalg.norm(points_arr[i] - points_arr[i - 1])
        branch_length += local_dist
    logging.debug(f"Total centreline length {branch_length}")

    return branch_length


def calc_smoothing(
    in_data: np.array, smo_filter: np.array, is_padded: bool = True
) -> np.array:
    """
    Apply smoothing to data by convolution with a filter

    Parameters
    ----------
    in_data: np.array
        Input data (radii) to be smoothed
    smo_filter: np.array
        Smoothing filter
    is_padded: bool
        Option to add zero padding at the ends of input data, to have output data with same dimension as input
    Returns
    -------
    Data after smoothing
    """
    if len(in_data) < len(smo_filter):
        logging.info(
            f"Size of input data {len(in_data)} smaller than filter window {len(smo_filter)}."
        )
        return in_data

    if is_padded:
        return np.convolve(in_data, smo_filter, "same")
    else:
        return np.convolve(in_data, smo_filter, "valid")


def calc_local_orientations(points: np.array, min_width: float) -> np.array:
    """
    Compute the local orientations at every point of centerline

    Parameters
    ----------
    points: np.array
        List of centerline points
    min_width: float
        Minimum distance between the two points used to compute the local orientation
        (I guess to avoid large "jumps" due to local oscillations in centerline points)

    Returns
    -------
    Orientations at every point of centerline
    """
    num_points = points.shape[0]
    orientations = np.zeros((num_points, 3))

    for i in range(num_points):
        # need to look for points at left / right of "i", at distance more than "width / 2", to compute the orientation

        if i == 0:  # special case for first (leftmost) point
            ind_l = 0
        else:
            points_left = points[:i]
            dists_points_left = distance.cdist([points[i]], points_left)[0]
            indexes_further_width = np.argwhere(dists_points_left > min_width / 2)
            if len(indexes_further_width) == 0:
                ind_l = 0
            else:
                ind_l = np.max(indexes_further_width)

        if i == num_points - 1:  # special case for last (rightmost) point
            ind_r = num_points - 1
        else:
            points_right = points[i + 1 :]
            dists_points_right = distance.cdist([points[i]], points_right)[0]
            indexes_further_width = np.argwhere(dists_points_right > min_width / 2)
            if len(indexes_further_width) == 0:
                ind_r = num_points - 1
            else:
                ind_r = i + 1 + np.min(indexes_further_width)

        orientation_this = points[ind_r, :] - points[ind_l, :]
        orientations[i, :] = orientation_this / np.linalg.norm(orientation_this)

    return orientations


# https://github.com/id-b3/Air_Flow_ImaLife/blob/03b0fd73c5fe87dae835caf67ed5b91edce079d0/airway_analysis/src_matlab/functions/measureAirways.m
def calc_tapering(yData: list, centreline_pos: list, perc: bool = False):
    """
    Calculates tapering slope and percentage for a measurement.
    :param: yData - list of measurements e.g. radius, area
    """

    yarr = np.array(yData)
    carr = np.array(centreline_pos)

    if len(yData) < 2:
        logging.warning(f"Not enough data for extraction of tapering info.")
        return None

    # xx = distance.pdist(carr, metric='euclidean')  # Calculate the euclidian distance between points along centreline.
    xx = np.zeros(carr.shape[0])
    for i in range(1, len(xx)):
        xx[i] = (
            distance.euclidean(carr[i - 1], carr[i]) + xx[i - 1]
        )  # Convert from relative distance to absolute distance.

    brfit = np.polyfit(xx, yarr, deg=1)  # Fit a linear polynomial to the points
    tapering = -brfit[0]
    tapering_perc = (-brfit[0] / brfit[1]) * 100

    if perc:
        return tapering_perc
    else:
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
    x = np.arange(-window_width, window_width + 1)
    kernel = np.exp(-(x**2) / (2 * sigma**2))
    kernel = kernel / np.sum(kernel)

    return kernel
