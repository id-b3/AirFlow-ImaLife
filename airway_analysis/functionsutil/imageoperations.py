from typing import Tuple
import numpy as np
from skimage.transform import rescale
from skimage.measure import label

BoundBoxType = Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]]


def compute_rescaled_image(
    in_image: np.ndarray, scale_factor: Tuple[float, float, float], order: int = 3
) -> np.ndarray:
    return rescale(
        in_image,
        scale=scale_factor,
        order=order,
        preserve_range=True,
        multichannel=False,
        anti_aliasing=True,
    )


def compute_thresholded_mask(in_image: np.ndarray, thres_val: float) -> np.ndarray:
    return np.where(in_image > thres_val, 1.0, 0.0).astype(np.int16)


def compute_connected_components(in_image: np.ndarray) -> Tuple[np.ndarray, int]:
    (out_image, out_num_regs) = label(
        in_image, connectivity=3, background=0, return_num=True
    )
    return (out_image.astype(in_image.dtype), out_num_regs)


def compute_boundbox_around_mask(
    in_image: np.ndarray, num_voxels_buffer: int
) -> BoundBoxType:
    indexes_posit_mask = np.argwhere(in_image != 0)
    out_boundbox = (
        (min(indexes_posit_mask[:, 0]), max(indexes_posit_mask[:, 0])),
        (min(indexes_posit_mask[:, 1]), max(indexes_posit_mask[:, 1])),
        (min(indexes_posit_mask[:, 2]), max(indexes_posit_mask[:, 2])),
    )

    return (
        (
            out_boundbox[0][0] - num_voxels_buffer,
            out_boundbox[0][1] + num_voxels_buffer,
        ),
        (
            out_boundbox[1][0] - num_voxels_buffer,
            out_boundbox[1][1] + num_voxels_buffer,
        ),
        (
            out_boundbox[2][0] - num_voxels_buffer,
            out_boundbox[2][1] + num_voxels_buffer,
        ),
    )


def compute_cropped_image(
    in_image: np.ndarray, in_crop_boundbox: BoundBoxType
) -> np.ndarray:
    return in_image[
        in_crop_boundbox[0][0] : in_crop_boundbox[0][1],
        in_crop_boundbox[1][0] : in_crop_boundbox[1][1],
        in_crop_boundbox[2][0] : in_crop_boundbox[2][1],
    ]


def compute_extended_image(
    in_image: np.ndarray,
    out_image_shape: Tuple[int, int, int],
    in_set_boundbox: BoundBoxType,
) -> np.ndarray:
    out_image = np.zeros(out_image_shape)
    out_image[
        in_set_boundbox[0][0] : in_set_boundbox[0][1],
        in_set_boundbox[1][0] : in_set_boundbox[1][1],
        in_set_boundbox[2][0] : in_set_boundbox[2][1],
    ] = in_image
    return out_image


def compute_setpatch_image(
    in_image: np.ndarray, out_image: np.ndarray, in_set_boundbox: BoundBoxType
) -> np.ndarray:
    out_image[
        in_set_boundbox[0][0] : in_set_boundbox[0][1],
        in_set_boundbox[1][0] : in_set_boundbox[1][1],
        in_set_boundbox[2][0] : in_set_boundbox[2][1],
    ] = in_image
    return out_image
