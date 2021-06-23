
from .functionutil import *
import numpy as np
from scipy.stats import pearsonr, spearmanr
from collections import OrderedDict
import csv
import sys



def read_file_data_csv(input_file, indexes_cols_read=None, typedata_cols_read=None):
    if not is_exist_file(input_file):
        print("ERROR: Input file \'%s\' does not exist... EXIT" % (input_file))
        sys.exit(0)

    with open(input_file, 'r') as fin:
        csv_reader = csv.reader(fin, delimiter=',')

        # read header and retrieve field labels
        header_row = next(csv_reader)
        list_fields = []
        if indexes_cols_read:
            for index in indexes_cols_read:
                if index > len(header_row):
                    print("ERROR. index in input \'indexes_cols_read\' larger than columns in file... EXIT")
                    return False
                in_field = header_row[index].replace(' ', '').replace('/', '')  # remove empty chars ' ' and closing '/'
                list_fields.append(in_field)
            # endfor
        else:
            for index in range(len(header_row)):
                in_field = header_row[index].replace(' ', '').replace('/', '')  # remove empty chars ' ' and closing '/'
                list_fields.append(in_field)
            # endfor

        # start with empty list and append values as the file rows are read
        out_dict = OrderedDict([(name_field, []) for name_field in list_fields])

        num_fields = len(list_fields)
        # read content of file and assign to dict with fields
        for i, row in enumerate(csv_reader):
            for k in range(num_fields):
                if indexes_cols_read:
                    index_field = indexes_cols_read[k]
                else:
                    index_field = k
                name_field      = list_fields[k]

                try:
                    if typedata_cols_read:
                        typedata_field = typedata_cols_read[k]
                        row_elem_field = typedata_field(row[index_field])
                    else:
                        row_elem_field = row[index_field]
                except:
                    # if exception reading the row element, assign NaN
                    row_elem_field = np.NaN

                out_dict[name_field].append(row_elem_field)
            # endfor
        # endfor

    return out_dict


def rearrange_data_as_images_from_list(indict_data, inlist_images):
    list_images_alldata = list(indict_data.values())[0]
    indexes_data_this_images = [i for i, it_image in enumerate(list_images_alldata) if it_image in inlist_images]

    outdict_data_this_images = OrderedDict()
    for name_field, data_field in indict_data.items():
        data_field_this_images = [data_field[index] for index in indexes_data_this_images]
        outdict_data_this_images[name_field] = data_field_this_images
    # endfor

    return outdict_data_this_images


def rearrange_data_as_each_images(indict_data):
    list_images_alldata = list(indict_data.values())[0]
    list_images_found   = np.unique(list_images_alldata)

    outdict_data_each_images = OrderedDict()
    for in_image in list_images_found:
        indexes_data_this_image = [i for i, it_image in enumerate(list_images_alldata) if it_image == in_image]

        outdict_data_this_image = OrderedDict()
        for name_field, data_field in indict_data.items():
            data_field_this_images = [data_field[index] for index in indexes_data_this_image]
            outdict_data_this_image[name_field] = data_field_this_images
        # endfor

        outdict_data_each_images[in_image] = outdict_data_this_image
    # endfor

    return outdict_data_each_images


def rearrange_measures_data_as_each_generation(indict_data, index_field_generation):
    list_generations_alldata = list(indict_data.values())[index_field_generation]
    list_generations_found   = np.unique(list_generations_alldata)
    max_generations_found    = np.max(list_generations_found) + 1 if (len(list_generations_found) > 0) else 1

    outdict_data_each_generations = OrderedDict()
    outdict_data_each_generations['num_branch_geners'] = []

    # create new fields to store the former fields split per generation
    for name_field, data_field in indict_data.items():
        name_field_gener = name_field + '_geners'
        outdict_data_each_generations[name_field_gener] = [[] for k in range(max_generations_found)]
    # endfor

    for i_gen in range(max_generations_found):
        indexes_data_this_gener = [k for k, it_gen in enumerate(list_generations_alldata) if it_gen == i_gen]
        num_branches_this_gener = len(indexes_data_this_gener)

        outdict_data_each_generations['num_branch_geners'].append(num_branches_this_gener)

        for name_field, data_field in indict_data.items():
            name_field_gener = name_field + '_geners'
            data_field_this_gener = [data_field[index] for index in indexes_data_this_gener]
            outdict_data_each_generations[name_field_gener][i_gen] = data_field_this_gener
        # endfor
    # endfor

    return outdict_data_each_generations



def clean_data_from_NaNs(inoutdict_data):
    for name_field, data_field in inoutdict_data.items():
        cleaned_data_field = [elem for elem in data_field if str(elem) != 'nan']
        inoutdict_data[name_field] = cleaned_data_field
    # endfor
    return inoutdict_data


def clean_measures_generations_from_NaNs(inoutdict_measures):
    for name_field, list_data_field in inoutdict_measures.items():
        if name_field == 'num_branch_geners':
            continue

        outlist_cleaned_data_field = []
        for data_field_this_gen in list_data_field:
            cleaned_data_field_this_gen = [elem for elem in data_field_this_gen if str(elem) != 'nan']
            outlist_cleaned_data_field.append(cleaned_data_field_this_gen)
        # endfor
            inoutdict_measures[name_field] = outlist_cleaned_data_field
    # endfor

    return inoutdict_measures


def clean_measures_pairedGT_from_NaNs(inoutdict_measures, indict_fields_indexes_calcstats):
    inlist_fields = list(inoutdict_measures.keys())
    inlist_data   = list(inoutdict_measures.values())

    for name_field, indexes_calcstats in indict_fields_indexes_calcstats.items():
        in_field_seg = inlist_fields[indexes_calcstats[0]]
        in_field_gt  = inlist_fields[indexes_calcstats[1]]
        in_data_seg  = inlist_data  [indexes_calcstats[0]]
        in_data_gt   = inlist_data  [indexes_calcstats[1]]

        indexes_nans_data_seg = [i for i,el in enumerate(in_data_seg) if str(el) == 'nan']
        indexes_nans_data_gt  = [i for i,el in enumerate(in_data_gt)  if str(el) == 'nan']
        indexes_nans_data_seg_and_gt = list(set(indexes_nans_data_seg + indexes_nans_data_gt))

        in_data_seg = [el for i,el in enumerate(in_data_seg) if i not in indexes_nans_data_seg_and_gt]
        in_data_gt  = [el for i,el in enumerate(in_data_gt)  if i not in indexes_nans_data_seg_and_gt]

        inoutdict_measures[in_field_seg] = in_data_seg
        inoutdict_measures[in_field_gt]  = in_data_gt
    # endfor

    return inoutdict_measures



def compute_median_data(in_data):
    return np.median(in_data)

def compute_percentile_data(in_data, in_percen):
    return np.percentile(in_data, in_percen)

def compute_whiskers_data(in_data):
    upper_quartile = np.percentile(in_data, 75)
    lower_quartile = np.percentile(in_data, 25)
    IQR = upper_quartile - lower_quartile

    in_data = np.array(in_data)
    upper_whisker = in_data[in_data <= upper_quartile + 1.5 * IQR].max()
    lower_whisker = in_data[in_data >= lower_quartile - 1.5 * IQR].min()
    return (upper_whisker, lower_whisker)

def compute_number_outliers_data(in_data):
    (upper_whisker, lower_whisker) = compute_whiskers_data(in_data)

    num_outliers_upper = sum(np.array(in_data) > upper_whisker)
    num_outliers_lower = sum(np.array(in_data) < lower_whisker)
    return (num_outliers_upper, num_outliers_lower)



def compute_median_measures_generations(indict_measures, max_num_generation=15):
    outdict_median_measures = OrderedDict()

    list_fields_measures = list(indict_measures.values())[0].keys()
    for in_field in list_fields_measures:
        outdict_median_measures[in_field] = [[] for i in range(max_num_generation)]
    # endfor

    for i, (in_image, indict_measures_this_image) in enumerate(indict_measures.items()):
        for in_field, inlist_data_this_field in indict_measures_this_image.items():
            if in_field == 'Patient_ID_geners':
                continue

            for i_gen, inlist_data_this_field_gen in enumerate(inlist_data_this_field):
                if i_gen >= max_num_generation:
                    break
                out_median_data_this_field_gen = np.median(inlist_data_this_field_gen)
                outdict_median_measures[in_field][i_gen].append(out_median_data_this_field_gen)
            # endfor
        # endfor
    # endfor

    return outdict_median_measures


def compute_statistics_measures_pairedGT(indict_measures, indict_fields_indexes_calcstats):
    inlist_fields = list(indict_measures.keys())
    inlist_data   = list(indict_measures.values())

    outdict_stats_measures = OrderedDict()

    for name_field, indexes_calcstats in indict_fields_indexes_calcstats.items():
        in_field_seg    = inlist_fields[indexes_calcstats[0]]
        in_field_gt     = inlist_fields[indexes_calcstats[1]]
        in_measures_seg = np.array(inlist_data[indexes_calcstats[0]])
        in_measures_gt  = np.array(inlist_data[indexes_calcstats[1]])

        if (name_field not in in_field_seg) or (name_field not in in_field_gt):
            print("ERROR. indexes to compute stats of '\%s'\ not valid: '\%s'\ and '\%s'\... EXIT" % (name_field, in_field_seg, in_field_gt))
            sys.exit(0)

        in_measures_seg = np.nan_to_num(in_measures_seg)  # remove NaNs and Infs

        out_diffmeasures= np.abs(in_measures_seg - in_measures_gt)/in_measures_gt
        out_meandiff    = np.mean(out_diffmeasures)
        out_stddiff     = np.std(out_diffmeasures)
        out_pearson     = pearsonr(in_measures_seg, in_measures_gt)[0]
        out_spearman    = spearmanr(in_measures_seg, in_measures_gt)[0]

        new_stats_measures = OrderedDict()
        new_stats_measures['meandiff'] = out_meandiff
        new_stats_measures['stddiff']  = out_stddiff
        new_stats_measures['pearson']  = out_pearson
        new_stats_measures['spearman'] = out_spearman

        outdict_stats_measures[name_field] = new_stats_measures
    # endfor

    return outdict_stats_measures



def generate_mask_location(in_coords, out_mask, in_label=1, val_inflate_mask=0):
    # location: the eight voxels closest to the input coordinates
    index_prev_coord_X = int(np.floor(in_coords[0]))
    index_prev_coord_Y = int(np.floor(in_coords[1]))
    index_prev_coord_Z = int(np.floor(in_coords[2]))
    index_locat_beg_X = index_prev_coord_X - val_inflate_mask
    index_locat_end_X = index_prev_coord_X + 1 + val_inflate_mask
    index_locat_beg_Y = index_prev_coord_Y - val_inflate_mask
    index_locat_end_Y = index_prev_coord_Y + 1 + val_inflate_mask
    index_locat_beg_Z = index_prev_coord_Z - val_inflate_mask
    index_locat_end_Z = index_prev_coord_Z + 1 + val_inflate_mask

    out_mask[index_locat_beg_Z:index_locat_end_Z + 1,
             index_locat_beg_Y:index_locat_end_Y + 1,
             index_locat_beg_X:index_locat_end_X + 1] = in_label


def check_location_inside_mask(in_coords, in_mask, thres_inside=0.75):
    # location: the eight voxels closest to the input coordinates
    index_prev_coord_X = int(np.floor(in_coords[0]))
    index_prev_coord_Y = int(np.floor(in_coords[1]))
    index_prev_coord_Z = int(np.floor(in_coords[2]))
    index_locat_beg_X = index_prev_coord_X
    index_locat_end_X = index_prev_coord_X + 1
    index_locat_beg_Y = index_prev_coord_Y
    index_locat_end_Y = index_prev_coord_Y + 1
    index_locat_beg_Z = index_prev_coord_Z
    index_locat_end_Z = index_prev_coord_Z + 1

    locat_in_mask = in_mask[index_locat_beg_Z:index_locat_end_Z + 1,
                            index_locat_beg_Y:index_locat_end_Y + 1,
                            index_locat_beg_X:index_locat_end_X + 1]
    mean_locat_in_mask = np.mean(locat_in_mask)

    if mean_locat_in_mask > thres_inside:
        return True
    else:
        return False