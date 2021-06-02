
from typing import Tuple, Any
from collections import OrderedDict
import numpy as np
import SimpleITK as sitk
import pydicom
import warnings
with warnings.catch_warnings():
    # disable FutureWarning: conversion of the second argument of issubdtype from `float` to `np.floating` is deprecated
    warnings.filterwarnings("ignore", category=FutureWarning)
    import nibabel as nib
import csv

from common.functionutil import fileextension, handle_error_message


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
        return cls._get_filereader_class(filename).update_image_metadata_info(in_metadata, **kwargs)

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
    def _get_filereader_class(filename: str) -> 'ImageFileReader':
        extension = fileextension(filename)
        if extension == '.nii' or extension == '.nii.gz':
            return NiftiReader
        elif extension == '.dcm':
            return DicomReader
        else:
            message = "Not valid file extension: %s..." % (extension)
            handle_error_message(message)


class NiftiReader(object):

    @classmethod
    def get_image_position(cls, filename: str) -> Tuple[float, float, float]:
        affine = nib.load(filename).affine
        return tuple(affine[:3, -1])

    @classmethod
    def get_image_voxelsize(cls, filename: str) -> Tuple[float, float, float]:
        affine = nib.load(filename).affine
        return tuple(np.abs(np.diag(affine)[:3]))

    @classmethod
    def get_image_metadata_info(cls, filename: str) -> Any:
        return nib.load(filename).affine

    @classmethod
    def get_image(cls, filename: str) -> np.ndarray:
        out_image = nib.load(filename).get_data()
        return np.swapaxes(out_image, 0, 2)

    @classmethod
    def write_image(cls, filename: str, in_image: np.ndarray, **kwargs) -> None:
        affine = kwargs['metadata'] if 'metadata' in kwargs.keys() else None
        in_image = np.swapaxes(in_image, 0, 2)
        nib_image = nib.Nifti1Image(in_image, affine)
        nib.save(nib_image, filename)


class DicomReader(object):

    @classmethod
    def get_image_position(cls, filename: str) -> Tuple[float, float, float]:
        ds = pydicom.read_file(filename)
        image_position_str = ds[0x0020, 0x0032].value   # Elem 'Image Position (Patient)'
        return (float(image_position_str[0]),
                float(image_position_str[1]),
                float(image_position_str[2]))

    @classmethod
    def get_image_voxelsize(cls, filename: str) -> Tuple[float, float, float]:
        ds = pydicom.read_file(filename)
        return (float(ds.SpacingBetweenSlices),
                float(ds.PixelSpacing[0]),
                float(ds.PixelSpacing[1]))

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
        if 'metadata' in kwargs.keys():
            dict_metadata = kwargs['metadata']
            for (key, val) in dict_metadata.items():
                image_write.SetMetaData(key, val)
        sitk.WriteImage(image_write, filename)


class CsvFileReader(object):

    @staticmethod
    def get_data_type(in_value_str: str) -> str:
        if in_value_str.isdigit():
            if in_value_str.count(' ') > 1:
                return 'group_integer'
            else:
                return 'integer'
        elif in_value_str.replace('.', '', 1).isdigit() and in_value_str.count('.') < 2:
            return 'float'
        else:
            return 'string'

    @classmethod
    def get_data(cls, input_file: str):
        with open(input_file, 'r') as fin:
            csv_reader = csv.reader(fin, delimiter=',')

            # read header and get field labels
            list_fields = next(csv_reader)
            list_fields = [elem.lstrip() for elem in list_fields]  # remove empty leading spaces ' '

            # output data as dictionary with (key: field_name, value: field data, same column)
            out_dict_data = OrderedDict([(ifield, []) for ifield in list_fields])

            num_fields = len(list_fields)
            for irow, row_data in enumerate(csv_reader):
                row_data = [elem.lstrip() for elem in row_data]  # remove empty leading spaces ' '

                if irow == 0:
                    # get the data type for each field
                    list_datatype_fields = []
                    for ifie in range(num_fields):
                        in_value_str = row_data[ifie]
                        in_data_type = cls.get_data_type(in_value_str)
                        list_datatype_fields.append(in_data_type)

                for ifie in range(num_fields):
                    field_name = list_fields[ifie]
                    in_value_str = row_data[ifie]
                    in_data_type = list_datatype_fields[ifie]

                    if in_value_str == 'NaN':
                        out_value = np.NaN
                    elif in_data_type == 'integer':
                        out_value = int(in_value_str)
                    elif in_data_type == 'group_integer':
                        out_value = tuple([int(elem) for elem in in_value_str.split(' ')])
                    elif in_data_type == 'float':
                        out_value = float(in_value_str)
                    else:
                        out_value = in_value_str

                    out_dict_data[field_name].append(out_value)

        return out_dict_data
