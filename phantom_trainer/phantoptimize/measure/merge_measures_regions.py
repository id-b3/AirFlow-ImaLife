
import argparse

from airway_analysis.functionsutil.functionsutil import *


def main(args):
    region_input_case = get_substring_filename(args.input_dir_region1, 'region[0-9]')
    if region_input_case != 'region1':
        message = 'Please input subdir for measures corresponding to \'region1\'...'
        handle_error_message(message)

    basedir_inputdir_region1 = dirnamedir(args.input_dir_region1)
    basename_inputdir_region1 = basenamedir(args.input_dir_region1).replace('_region1', '')

    list_in_dirs_regions = list_dirs_dir(basedir_inputdir_region1, basename_inputdir_region1 + '*')

    # sort input subdirs from region 1 - 8
    list_in_dirs_regions.sort(key=lambda name: get_substring_filename(name, 'region[0-9]'))

    # ----------

    outputdir = join_path_names(basedir_inputdir_region1, basename_inputdir_region1)
    out_filename = join_path_names(outputdir, './Opfront_ResultsPerBranch.csv')

    makedir(outputdir)

    with open(out_filename, 'w') as fout:

        for ireg, indir_thisreg in enumerate(list_in_dirs_regions):
            in_filename = join_path_names(indir_thisreg, './Opfront_ResultsPerBranch.csv')

            try:
                with open(in_filename) as fin:
                    if ireg == 0:
                        # copy the header from the input file from region 1 in output file
                        header_infile = fin.readline()
                        fout.write(header_infile)
                    else:
                        fin.readline()  # skip header

                    strdata_infile = fin.readline()
                    first_elem_strdata = strdata_infile.split(', ')[0]
                    first_elem_strdata_new = first_elem_strdata + '_region%d' % (ireg + 1)
                    # add suffix with region number to the first elem 'casename'
                    strdata_infile = strdata_infile.replace(first_elem_strdata, first_elem_strdata_new)
                    fout.write(strdata_infile)

            except IOError as e:
                print('ERROR. Cannot read data in \'%s\'. '
                      'Add dummy line in output file and skip this region... ' % (indir_thisreg))

                list_dummy_data = ['COPDGene_Phantom_Qr59_region%d' % (ireg + 1)] \
                                  + ['000'] + ['0.0'] * 6 + ['0'] * 2 + [''] + ['0.0'] * 3 + ['NaN'] * 2
                strdata_infile = ', '.join(list_dummy_data) + '\n'
                fout.write(strdata_infile)
                continue


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input_dir_region1', type=str)
    args = parser.parse_args()

    main(args)
