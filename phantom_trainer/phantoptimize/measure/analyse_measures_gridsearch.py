
import numpy as np
import matplotlib.pyplot as plt
import argparse


def main(args):

    # SETTINGS
    pattern_suffix_cases_analyse = 'i[0-9]+_I1_o[0-9]+_O1_M3_N5'
    # pattern_suffix_cases_analyse = 'i15_I2_o15_O2_w[0-9]+'
    # pattern_suffix_cases_analyse = 'i15_I2_o15_O2_b[0-9]+'
    pattern_main_param_suffix = 'i[0-9]+'

    in_reference_filename = join_path_names(args.basedir, './COPDGene_Phantom_Measurements.csv')
    input_dir_all = join_path_names(args.basedir, './Phantom_Measurements_Regions_All/')

    # ----------

    list_in_subdirs_all = list_dirs_dir(input_dir_all, '*')

    list_in_subdirs_cases = [isubdir for isubdir in list_in_subdirs_all
                             if get_substring_filename(isubdir, pattern_suffix_cases_analyse) is not None]

    # sort subdirs in increasing order of the param
    list_in_subdirs_cases.sort(key=lambda name: int(re.search(pattern_main_param_suffix, name)[0][1:]))

    print("Analyse measures from files in subdirs:")
    print("%s" % ('\n'.join(list_in_subdirs_cases)))

    # ----------

    in_data_reference = np.genfromtxt(in_reference_filename, dtype=float, delimiter=',', skip_header=1)

    # check the location of each tube in Phantom in the file 'COPDGene_Airways.pdf'
    #                       / tube_phantom /        / region_input_measures /
    # (from left to right)    8 7 6 5 4 3 2 1   ->    3 6 4 2 8 5 1 7
    map_index_input_to_refer = [1, 4, 7, 5, 2, 6, 0, 3]

    refer_inner_diam_regs = in_data_reference[:, 1]
    refer_outer_diam_regs = in_data_reference[:, 2]
    refer_length_regs = in_data_reference[:, 3]

    refer_inner_diam_regs = refer_inner_diam_regs[map_index_input_to_refer]
    refer_outer_diam_regs = refer_outer_diam_regs[map_index_input_to_refer]
    refer_length_regs = refer_length_regs[map_index_input_to_refer]

    # ----------

    num_regions = 8
    num_cases = len(list_in_subdirs_cases)

    error_inner_diam_regs_all = np.zeros((num_regions, num_cases))
    error_outer_diam_regs_all = np.zeros((num_regions, num_cases))
    error_length_regs_all = np.zeros((num_regions, num_cases))

    # read measurements from files
    for icase, in_subdir in enumerate(list_in_subdirs_cases):
        in_filename = join_path_names(in_subdir, './Opfront_ResultsPerBranch.csv')

        try:
            in_data = np.genfromtxt(in_filename, dtype=float, delimiter=', ', skip_header=1)
        except:
            continue

        in_inner_diam_regs = in_data[:, 5]
        in_outer_diam_regs = in_data[:, 6]
        in_length_regs = in_data[:, 7]

        error_inner_diam_regs_this = np.abs(in_inner_diam_regs - refer_inner_diam_regs)
        error_outer_diam_regs_this = np.abs(in_outer_diam_regs - refer_outer_diam_regs)
        error_length_regs_this = np.abs(in_length_regs - refer_length_regs)

        error_inner_diam_regs_all[:, icase] = error_inner_diam_regs_this
        error_outer_diam_regs_all[:, icase] = error_outer_diam_regs_this
        error_length_regs_all[:, icase] = error_length_regs_this
    # endfor

    # ----------

    # plot erros for measurements of 'inner_diam', 'outer_diam', 'length'
    list_errors_data_all = [error_inner_diam_regs_all, error_outer_diam_regs_all, error_length_regs_all]
    list_labels_data_all = ['error_inner_diam', 'error_outer_diam', 'error_length']

    # cmap = plt.get_cmap('rainbow')
    # colors = [cmap(float(i) / (num_regions - 1)) for i in range(num_regions)]

    for iplot in range(3):
        print("\n plot error in measurement \'%s\'..." % (list_labels_data_all[iplot]))

        fig, axis = plt.subplots(2, 4, figsize=(10, 5))
        iter_axis = axis.flat

        xaxis_plot_range = np.arange(1, num_cases + 1)

        for ireg in range(num_regions):
            next_axis = next(iter_axis)

            next_axis.plot(xaxis_plot_range, list_errors_data_all[iplot][ireg])
            next_axis.set_xlabel('index_cases')
            next_axis.set_ylabel('error_reg%s' % (ireg + 1))
        # endfor

        fig.suptitle('\'%s\', all regions' % (list_labels_data_all[iplot]))
        plt.show()
    # endfor



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--basedir', type=str, default='.')
    args = parser.parse_args()

    main(args)
