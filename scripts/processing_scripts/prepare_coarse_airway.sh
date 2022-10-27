#!/bin/bash

IN_AIRWAY_DIR=${1}

AIR_FILE=$(find "$IN_AIRWAY_DIR" -type f -name "*-airways.dcm")
AIR_NO_EXT=${AIR_FILE%.*}
TEMP_AIR_DIR=./TEMP_AIR_PROC
NIFTI_DIR=${TEMP_AIR_DIR}/NIFTI_AIR
FILLED_DIR=${TEMP_AIR_DIR}/FILLED_DIR
FILLED_FILE=${FILLED_DIR}/filled.nii.gz
BRANCH_OUT_FILE=${FILLED_DIR}/filled.nii-branch.nii.gz
MASKED_DIR=${TEMP_AIR_DIR}/MASKED_DIR
FINAL_DIR=${TEMP_AIR_DIR}/FINAL_DIR
BRANCH_VOL=${MASKED_DIR}/filled_brh.nii.gz

# Make all folders
mkdir -p $MASKED_DIR $FILLED_DIR $NIFTI_DIR $FINAL_DIR

# 1. Convert to NIFTI
python Code/scripts_util/convert_images_to_nifti.py "$IN_AIRWAY_DIR" $NIFTI_DIR
rm "$AIR_FILE"
# 2. Binarise and fill holes
python Code/scripts_util/apply_operation_images.py $NIFTI_DIR $FILLED_DIR --type binarise fillholes
# 3. Fill Holes extra
holefiller -i $FILLED_DIR/*.nii.gz -o $FILLED_FILE
# 4. Branch Extractor
be $FILLED_FILE -o $FILLED_DIR
mv $BRANCH_OUT_FILE $BRANCH_VOL
# 5. Mask labels
python Code/scripts_util/apply_operation_images.py $MASKED_DIR $FINAL_DIR --type masklabels --in_mask_labels 1 2 3 4 5 6 7 8 9 10 11 12 13 14
mv $FINAL_DIR/*.nii.gz "$AIR_NO_EXT".nii.gz
# 6. Clean up
rm -r $TEMP_AIR_DIR
