#!/bin/bash


codedir="../python/phantom_copdgene/"
basedir=${1:-/home/antonio/Results/TEST/}

folder_in_measures_region1="${basedir}/Phantom_Opfronted_F-0.1_G-0.2_region1"


# 1: merge the .csv measurement files for each region
CALL="python3 ${codedir}/merge_measures_regions.py ${folder_in_measures_region1}"
echo $CALL
eval $CALL
