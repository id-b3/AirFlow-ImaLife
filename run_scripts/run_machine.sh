#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT=${1:-/eureka/input/dicom-series-in/*.dcm}
OUTPUTFOLDER=${2:-/eureka/output/nifti-series-out/}
INPUTFILE=${3:-/eureka/input/dicom-series-in/proc_scan.dcm}

mkdir -p /eureka/input/dicom-series-in/
CALL="python /bronchinet/airway_analysis/util_scripts/fix_transfer_syntax.py ${INPUT} ${INPUTFILE}"
eval "$CALL"

echo "Input File: ${INPUTFILE}"
echo "Output Folder: ${2}"

DATADIR=/temp_work/processing
DESTAIR=${DATADIR}/CoarseAirways
DESTLUNG=${DATADIR}/Lungs
DESTIMG=${DATADIR}/RAW/DICOM
NIFTIIMG=${DATADIR}/Images

MODELFILE=/bronchinet/model/model_imalife.pt

# RESULTS DIRS
RESDIR=/temp_work/results
POSWRKDIR=${RESDIR}/PosteriorsWorkData
POSDIR=${RESDIR}/Posteriors
KEYFILE=${RESDIR}/referenceKeys_posteriors.npy

echo "Running Lung Segmentation. Destination folder $DESTLUNG"
echo "-------------------------------------------------------"

mkdir -p $DESTAIR
mkdir -p $DESTLUNG
mkdir -p $DESTIMG
mkdir -p "${OUTPUTFOLDER}"
mkdir -p /temp_work/processing/Airways

cp "$INPUTFILE" $DESTIMG/
cd /temp_work || exit
ln -s /bronchinet/src Code
ln -s /temp_work/processing BaseData

lung_segmentation --verbose false --source "$INPUTFILE" --savepath $DESTLUNG
if [ $? -eq 0 ]
then
  echo "Segmented Lungs"
  rm $DESTLUNG/*.bmp
  mv $DESTLUNG/*-airways.dcm $DESTAIR/
else
  echo "Could not segment lungs. Terminating."
  exit $?
fi

echo 'CONVERTING DICOM TO NIFTY'
echo '-------------------------'
python Code/scripts_util/convert_images_to_nifti.py $DESTIMG $NIFTIIMG

echo 'Pre-Processing...........'
echo '-------------------------'
python Code/scripts_preparedata/compute_boundingbox_images.py --datadir=$DATADIR
python Code/scripts_preparedata/prepare_data.py --datadir=$DATADIR --is_prepare_labels=False

echo '-------------------------'
echo 'Distributing Data........'
echo '-------------------------'
python Code/scripts_experiments/distribute_data.py --basedir=/temp_work --type_data=testing --propdata_train_valid_test="(0,0,1)"

echo '-------------------------'
echo 'Predict Segmentation.....'
echo '-------------------------'
python Code/scripts_experiments/predict_model.py --basedir=/temp_work --testing_datadir=TestingData --is_backward_compat=True --name_output_predictions_relpath=${POSWRKDIR} --name_output_reference_keys_file=${KEYFILE} ${MODELFILE}

echo '-------------------------'
echo 'Post-process Segmentation'
echo '-------------------------'
python Code/scripts_evalresults/postprocess_predictions.py --basedir=/temp_work --name_input_predictions_relpath=${POSWRKDIR} --name_output_posteriors_relpath=${POSDIR} --name_input_reference_keys_file=${KEYFILE}
python Code/scripts_evalresults/process_predicted_airway_tree.py --basedir=/temp_work --name_input_posteriors_relpath=${POSDIR} --name_output_binary_masks_relpath=${RESDIR}

echo '-------------------------'
echo 'CLEAN UP.................'
echo '-------------------------'
rm -r ${POSDIR}
rm -r ${POSWRKDIR}
rm ${KEYFILE}

echo '-------------------------'
echo 'RUNNING OPFRONT..........'
echo '-------------------------'


/bronchinet/scripts/opfront_scripts/opfront_one_scan.sh ${NIFTIIMG}/*.nii.gz ${RESDIR}/*.nii.gz "${OUTPUTFOLDER}" "-i 15 -o 15 -I 2 -O 2 -d 0 -b 0.4 -k 0.5 -r 0.7 -c 17 -e 0.7 -K 0 -F -0.588 -G -0.688"
python /bronchinet/airway_analysis/airway_summary.py ${NIFTIIMG}/*.nii.gz --inner_csv ${OUTPUTFOLDER}/*_inner.csv --inner_rad_csv ${OUTPUTFOLDER}/*_inner_localRadius_pandas.csv --outer_csv ${OUTPUTFOLDER}/*_outer.csv --outer_rad_csv ${OUTPUTFOLDER}/*_outer_localRadius_pandas.csv --branch_csv ${OUTPUTFOLDER}/*_airways_centrelines.csv
