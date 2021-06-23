#!/bin/bash


codedir="../python/phantom_copdgene/"
basedir=${1:-/home/ivan/Results/TEST/}

initial_segmen="${basedir}/phantom-volume.nii.gz"
folder_in_segmens="${basedir}/Phantom_Opfronted_Optimal_i48_I2_o23_O2"


# 1: compute the coordinates of bounding-boxes for the 8 regions of COPDgene phantom
CALL="python3 ${codedir}/compute_boundbox_regions.py ${initial_segmen}"
echo $CALL
eval $CALL


# 2: split the input segmentations for each region
CALL="python3 ${codedir}/split_segmentation_regions.py ${folder_in_segmens}"
echo $CALL
eval $CALL


# 3: compress the output dicom files
# list_out_segmens=$(find ${folder_in_segmens}_region[0-9] -type f)

# for ifile in $list_out_segmens
# do
#     CALL="dcmcjpeg $ifile $ifile"
#     echo $CALL
#     eval $CALL
# done
