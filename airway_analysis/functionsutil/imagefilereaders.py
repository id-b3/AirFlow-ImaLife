from typing import Tuple, Any
import numpy as np
import SimpleITK as sitk
import pydicom
import warnings

with warnings.catch_warnings():
    # disable FutureWarning: conversion of the second argument of issubdtype from `float` to `np.floating` is deprecated
    warnings.filterwarnings("ignore", category=FutureWarning)
    import nibabel as nib

from functionsutil.functionsutil import fileextension, handle_error_message


class ImageFileReader(object):
    @classmethod
    def get_image_position(cls, filename: str) -> Tuple[float, float, float]:
        return cls._get_filereader_class(filename).get_image_position(filename)

    @classmethod
    def get_image_voxelsize(cls, filename: str) -> Tuple[float, float, float]:
        return cls._get_filereader_class(filename).get_image_voxelsize(filename)

    @classmethod
    def get_image_metadata_info(cls, filename: str) -> Any:
        return cls._get_filereader_class(filename).get_image_metadata_info(filename)

    @classmethod
    def update_image_metadata_info(cls, filename: str, **kwargs) -> Any:
        in_metadata = cls.get_image_metadata_info(filename)
        return cls._get_filereader_class(filename).update_image_metadata_info(
            in_metadata, **kwargs
        )

    @classmethod
    def get_image_size(cls, filename: str) -> Tuple[int, int, int]:
        return cls.get_image(filename).shape

    @classmethod
    def get_image(cls, filename: str) -> np.ndarray:
        return cls._get_filereader_class(filename).get_image(filename)

    @classmethod
    def write_image(cls, filename: str, in_image: np.ndarray, **kwargs) -> None:
        cls._get_filereader_class(filename).write_image(filename, in_image, **kwargs)

    @staticmethod
    def _get_filereader_class(filename: str) -> "ImageFileReader":
        extension = fileextension(filename)
        if extension == ".nii" or extension == ".nii.gz":
            return NiftiReader
        elif extension == ".dcm":
            return DicomReader
        else:
            message = f"Not valid file extension: {extension}"
            handle_error_message(message)


class NiftiReader(ImageFileReader):
    @classmethod
    def get_image_position(cls, filename: str) -> Tuple[float, float, float]:
        affine = cls._get_image_affine_matrix(filename)
        return tuple(affine[:3, -1])

    @classmethod
    def get_image_voxelsize(cls, filename: str) -> Tuple[float, float, float]:
        affine = cls._get_image_affine_matrix(filename)
        return tuple(np.abs(np.diag(affine)[:3]))

    @classmethod
    def _get_image_affine_matrix(cls, filename: str) -> np.ndarray:
        affine = nib.load(filename).affine
        return cls._fix_dims_affine_matrix(affine)

    @classmethod
    def get_image_metadata_info(cls, filename: str) -> Any:
        return cls._get_image_affine_matrix(filename)

    @classmethod
    def get_image(cls, filename: str) -> np.ndarray:
        out_image = nib.load(filename).get_data()
        return cls._fix_dims_image_read(out_image)

    @classmethod
    def write_image(cls, filename: str, in_image: np.ndarray, **kwargs) -> None:
        if "metadata" in kwargs.keys():
            affine = kwargs["metadata"]
            affine = cls._fix_dims_affine_matrix(affine)
        else:
            affine = None
        in_image = cls._fix_dims_image_write(in_image)
        nib_image = nib.Nifti1Image(in_image, affine)
        nib.save(nib_image, filename)

    @staticmethod
    def _fix_dims_affine_matrix(inout_affine: np.ndarray) -> np.ndarray:
        # Change dims from (dx, dy, dz) to (dz, dy, dx)
        inout_affine[[0, 2], :] = inout_affine[[2, 0], :]
        inout_affine[:, [0, 2]] = inout_affine[:, [2, 0]]
        return inout_affine

    @staticmethod
    def _fix_dims_image_read(in_image: np.ndarray) -> np.ndarray:
        # Roll dims from (dx, dy, dz) to (dz, dy, dx)
        return np.swapaxes(in_image, 0, 2)

    @staticmethod
    def _fix_dims_image_write(in_image: np.ndarray) -> np.ndarray:
        # Roll dims from (dz, dy, dx) to (dx, dy, dz)
        return np.swapaxes(in_image, 0, 2)


class DicomReader(ImageFileReader):
    @classmethod
    def get_image_position(cls, filename: str) -> Tuple[float, float, float]:
        ds = pydicom.read_file(filename)
        image_position_str = ds[0x0020, 0x0032].value  # Elem 'Image Position (Patient)'
        return (
            float(image_position_str[0]),
            float(image_position_str[1]),
            float(image_position_str[2]),
        )

    @classmethod
    def get_image_voxelsize(cls, filename: str) -> Tuple[float, float, float]:
        ds = pydicom.read_file(filename)
        return (
            float(ds.SpacingBetweenSlices),
            float(ds.PixelSpacing[0]),
            float(ds.PixelSpacing[1]),
        )

    @classmethod
    def get_image_metadata_info(cls, filename: str) -> Any:
        image_read = sitk.ReadImage(filename)
        metadata_keys = image_read.GetMetaDataKeys()
        return {key: image_read.GetMetaData(key) for key in metadata_keys}

    @classmethod
    def get_image(cls, filename: str) -> np.ndarray:
        image_read = sitk.ReadImage(filename)
        return sitk.GetArrayFromImage(image_read)

    @classmethod
    def write_image(cls, filename: str, in_image: np.ndarray, **kwargs) -> None:
        if in_image.dtype != np.uint16:
            in_image = in_image.astype(np.uint16)
        image_write = sitk.GetImageFromArray(in_image)
        if "metadata" in kwargs.keys():
            dict_metadata = kwargs["metadata"]
            for (key, val) in dict_metadata.items():
                image_write.SetMetaData(key, val)
        sitk.WriteImage(image_write, filename)
