#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUTFILE=$1

echo "Input File: $1"

DATADIR=/temp_work/processing
DESTAIR=${DATADIR}/CoarseAirways
DESTLUNG=${DATADIR}/Lungs
DESTIMG=${DATADIR}/RAW/DICOM
NIFTIIMG=${DATADIR}/Images

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
mkdir -p /temp_work/processing/Airways

cd /temp_work/

ln -s /bronchinet/src Code
ln -s /temp_work/processing BaseData

lung_segmentation --source $INPUTFILE --savepath $DESTLUNG
rm $DESTLUNG/*.bmp
mv $DESTLUNG/*-airways.dcm $DESTAIR/
cp $INPUTFILE $DESTIMG/

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
python Code/scripts_experiments/predict_model.py --basedir=/temp_work --testing_datadir=TestingData --is_backward_compat=True --name_output_predictions_relpath=${POSWRKDIR} --name_output_reference_keys_file=${KEYFILE} /bronchinet/model/model_imalife.pt

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
echo 'PROVIDE RESULTS..........'
echo '-------------------------'
cp -r ${RESDIR} /input
