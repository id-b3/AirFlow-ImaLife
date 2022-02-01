import logging
from typing import List, Tuple, Dict, Any
from collections import OrderedDict
import csv
import struct

import numpy as np


class CsvFileReader(object):
    @staticmethod
    def get_data_type(in_value_str: str) -> str:
        if in_value_str.isdigit():
            if in_value_str.count(" ") > 1:
                return "group_integer"
            else:
                return "integer"
        elif in_value_str.replace(".", "", 1).isdigit() and in_value_str.count(".") < 2:
            return "float"
        else:
            return "string"

    @classmethod
    def get_data(cls, input_file: str) -> Dict[str, List[Any]]:
        with open(input_file, "r") as fin:
            csv_reader = csv.reader(fin, delimiter=",")

            # read header and get field labels
            list_fields = next(csv_reader)
            list_fields = [
                elem.lstrip() for elem in list_fields
            ]  # remove empty leading spaces ' '

            # output data as dictionary with (key: field_name, value: field data, same column)
            out_dict_data = OrderedDict([(ifield, []) for ifield in list_fields])

            num_fields = len(list_fields)
            for irow, row_data in enumerate(csv_reader):
                row_data = [
                    elem.lstrip() for elem in row_data
                ]  # remove empty leading spaces ' '

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

                    if in_value_str == "NaN" and in_value_str == "nan":
                        out_value = np.NaN
                    elif in_data_type == "integer":
                        out_value = int(in_value_str)
                    elif in_data_type == "group_integer":
                        out_value = tuple(
                            [int(elem) for elem in in_value_str.split(" ")]
                        )
                    elif in_data_type == "float":
                        out_value = float(in_value_str)
                    else:
                        out_value = in_value_str

                    out_dict_data[field_name].append(out_value)

        return out_dict_data


class BranchFileReader(object):
    # branch is binary file
    _size_bool = 1
    _size_int = 4
    _size_double = 8
    _bindata_all = None
    _count = -1
    _max_count = -1
    _fout = None

    @classmethod
    def get_data(cls, input_file: str) -> Dict[str, List[Any]]:
        with open(input_file, "rb") as fin:
            cls._initialize_read(fin)

            out_data = OrderedDict()
            out_data["index"] = []
            out_data["parent"] = []
            out_data["generation"] = []
            out_data["ignore"] = []
            out_data["maxRadius"] = []
            out_data["children"] = []
            out_data["points"] = []

            num_branches_incl_dummy = cls._read_elem_int()
            while cls._count < cls._max_count:

                out_data["index"].append(cls._read_elem_int())
                out_data["parent"].append(cls._read_elem_int())
                out_data["generation"].append(cls._read_elem_int())
                out_data["ignore"].append(cls._read_elem_bool())
                out_data["maxRadius"].append(cls._read_elem_double())

                num_children_brh = cls._read_elem_int()
                children_brh = [cls._read_elem_int() for j in range(num_children_brh)]
                out_data["children"].append(children_brh)

                num_points_brh = cls._read_elem_int()
                points_brh = [
                    [cls._read_elem_double() for k in range(3)]
                    for j in range(num_points_brh)
                ]
                out_data["points"].append(points_brh)

            return out_data

    @classmethod
    def _initialize_read(cls, fin) -> None:
        cls._bindata_all = fin.read()
        cls._count = 0
        cls._max_count = len(cls._bindata_all)

    @classmethod
    def _read_elem_bool(cls) -> bool:
        # out_elem = bool.from_bytes(cls._data_all[cls._count:cls._count + cls._size_bool], byteorder='little')
        out_elem = bool(
            struct.unpack(
                "?", cls._bindata_all[cls._count : cls._count + cls._size_bool]
            )[0]
        )
        cls._count += cls._size_bool
        return out_elem

    @classmethod
    def _read_elem_int(cls) -> int:
        # out_elem = int.from_bytes(cls._data_all[cls._count:cls._count + cls._size_int], byteorder='little')
        out_elem = struct.unpack(
            "i", cls._bindata_all[cls._count : cls._count + cls._size_int]
        )[0]
        cls._count += cls._size_int
        return out_elem

    @classmethod
    def _read_elem_double(cls) -> float:
        out_elem = struct.unpack(
            "d", cls._bindata_all[cls._count : cls._count + cls._size_double]
        )[0]
        cls._count += cls._size_double
        return out_elem

    @classmethod
    def write_data(cls, output_file: str, out_data: Dict[str, List[Any]]) -> None:
        logging.debug(f"Writing Data to {output_file}")
        logging.debug(f"{out_data}")

        with open(output_file, "wb") as fout:
            cls._initialize_write(fout)

            num_branches_incl_dummy = max(out_data["index"]) + 1
            cls._write_elem_int(num_branches_incl_dummy)

            num_branches = len(out_data["index"])
            # Offset the range to account for indexing starting at 1
            for ibr in range(num_branches):
                logging.debug(f"Writing branch {ibr} to branch file.")
                cls._write_elem_int(out_data["index"][ibr])
                cls._write_elem_int(out_data["parent"][ibr])
                cls._write_elem_int(out_data["generation"][ibr])
                cls._write_elem_bool(out_data["ignore"][ibr])
                cls._write_elem_float(out_data["maxRadius"][ibr])

                num_children_brh = len(out_data["children"][ibr])
                cls._write_elem_int(num_children_brh)
                for j in range(num_children_brh):
                    cls._write_elem_int(out_data["children"][ibr][j])

                num_points_brh = len(out_data["points"][ibr])
                cls._write_elem_int(num_points_brh)
                for j in range(num_points_brh):
                    for k in range(3):
                        cls._write_elem_float(out_data["points"][ibr][j][k])

    @classmethod
    def _initialize_write(cls, fout) -> None:
        cls._fout = fout
        cls._bindata_all = None

    @classmethod
    def _write_elem_bool(cls, in_elem: bool) -> None:
        # cls._bindata_all += struct.pack('?', in_elem)
        cls._fout.write(struct.pack("?", in_elem))

    @classmethod
    def _write_elem_int(cls, in_elem: int) -> None:
        # cls._bindata_all += struct.pack('i', in_elem)
        cls._fout.write(struct.pack("i", in_elem))

    @classmethod
    def _write_elem_float(cls, in_elem: float) -> None:
        # cls._bindata_all += struct.pack('d', in_elem)
        cls._fout.write(struct.pack("d", in_elem))
