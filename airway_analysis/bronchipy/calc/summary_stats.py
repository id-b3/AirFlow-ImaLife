import logging
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from .visualise import save_pi10_figure
from sklearn.linear_model import LinearRegression


def fractal_dimension(
    array, max_box_size=None, min_box_size=1, n_samples=20, n_offsets=0, plot=False,
    binarize=True
):
    """Calculates the fractal dimension of a 3D numpy array.

    Args:
        array (np.ndarray): The array to calculate the fractal dimension of.
        max_box_size (int): The largest box size, given as the power of 2 so that
                            2**max_box_size gives the sidelength of the largest box.
        min_box_size (int): The smallest box size, given as the power of 2 so that
                            2**min_box_size gives the sidelength of the smallest box.
                            Default value 1.
        n_samples (int): number of scales to measure over.
        n_offsets (int): number of offsets to search over to find the smallest set N(s) to
                       cover  all voxels>0.
        plot (bool): set to true to see the analytical plot of a calculation.


    """
    if binarize:
        array = np.where(array > 0.3, array, 1)

    # determine the scales to measure on
    if max_box_size is None:
        # default max size is the largest power of 2 that fits in the smallest dimension of the array:
        max_box_size = int(np.floor(np.log2(np.min(array.shape))))
    scales = np.floor(np.logspace(max_box_size, min_box_size, num=n_samples, base=2))
    scales = np.unique(scales)  # remove duplicates that occur due to floor

    # get the locations of all non-zero pixels
    locs = np.where(array > 0)
    voxels = np.array([(x, y, z) for x, y, z in zip(*locs)])

    # count the minimum amount of boxes touched
    Ns = []
    # loop over all scales
    for scale in scales:
        touched = []
        if n_offsets == 0:
            offsets = [0]
        else:
            offsets = np.linspace(0, scale, n_offsets)
        # search over all offsets
        for offset in offsets:
            bin_edges = [np.arange(0, i, scale) for i in array.shape]
            bin_edges = [np.hstack([0 - offset, x + offset]) for x in bin_edges]
            H1, e = np.histogramdd(voxels, bins=bin_edges)
            touched.append(np.sum(H1 > 0))
        Ns.append(touched)
    Ns = np.array(Ns)

    # From all sets N found, keep the smallest one at each scale
    Ns = Ns.min(axis=1)

    # Only keep scales at which Ns changed
    scales = np.array([np.min(scales[Ns == x]) for x in np.unique(Ns)])

    Ns = np.unique(Ns)
    Ns = Ns[Ns > 0]
    scales = scales[: len(Ns)]
    # perform fit
    coeffs = np.polyfit(np.log(1 / scales), np.log(Ns), 1)

    # make plot
    if plot:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.scatter(
            np.log(1 / scales), np.log(np.unique(Ns)), c="teal", label="Measured ratios"
        )
        ax.set_ylabel("$\log N(\epsilon)$")
        ax.set_xlabel("$\log 1/ \epsilon$")
        fitted_y_vals = np.polyval(coeffs, np.log(1 / scales))
        ax.plot(
            np.log(1 / scales),
            fitted_y_vals,
            "k--",
            label=f"Fit: {np.round(coeffs[0],3)}X+{coeffs[1]}",
        )
        ax.legend()
    return coeffs[0]


def calc_pi10(
    wa: list, rad: list, plot: bool = False, name: str = "anon", save_dir: str = "./"
) -> float:

    # Calculate regression line
    x = np.array(rad).reshape((-1, 1))
    x = (2 * np.pi) * x
    logging.debug(f"Radii {rad}\nPerimeters {x}")
    y = np.array(wa)
    y = np.sqrt(y)
    logging.debug(f"Square Root Wall Areas {y}")

    # Calculate best fit for regression line
    pi10_model = LinearRegression(n_jobs=-1).fit(x, y)
    logging.info(f"Pi10 R2 value is: {pi10_model.score(x, y)}")
    logging.info(f"Slope {pi10_model.coef_} and intercept {pi10_model.intercept_}")

    # Get sqrt WA for hypothetical airway of 10mm internal perimeter
    pi10 = pi10_model.predict([[10]])

    if plot:
        save_pi10_figure(x, y, pi10_model, pi10, name=name, savedir=save_dir)

    return pi10[0]


def param_by_gen(air_tree: pd.DataFrame, gen: int, param: str) -> float:
    """

    Parameters
    ----------
    param    : parameter to summarise
    gen      : generation to summarise
    air_tree : pandas dataframe
    """
    return air_tree.groupby("generation")[param].describe().at[gen, "mean"]
    # return air_tree[[param, "generation"]].groupby("generation").describe().at[gen, "mean"]


def agg_param(tree: pd.DataFrame, gens: list, param: str) -> float:
    """

    Parameters
    ----------
    tree
    gens
    param
    """

    return tree[(tree.generation >= gens[0]) & (tree.generation <= gens[1])][
        param
    ].mean()


def total_count(tree: pd.DataFrame) -> int:
    return tree.index.max()
