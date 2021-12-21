#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT_DIR=${1}
VOL_FILE=${2}
VOL_NO_EXTENSION="${VOL_FILE%.*}"
OUTPUTFOLDER=${3}
LOGFILE=${4:-./PROCESS_LOG.log}

#mkdir -p /eureka/input/dicom-series-in/
#CALL="python /bronchinet/airway_analysis/util_scripts/fix_transfer_syntax.py ${INPUT_DIR} ${INPUTFILE}"
#eval "$CALL"

echo "Input File: ${VOL_FILE}"
echo "Output Folder: ${3}"

DATADIR=/temp_work/processing
DESTAIR=${DATADIR}/CoarseAirways
DESTLUNG=${DATADIR}/Lungs
DESTIMG=${DATADIR}/RAW/DICOM
NIFTIIMG=${DATADIR}/Images

MODELFILE=/bronchinet/model/model_imalife.pt

# RESULTS DIRS
RESDIR=/temp_work/results
SEGDIR=${RESDIR}/${VOL_NO_EXTENSION}
POSWRKDIR=${RESDIR}/PosteriorsWorkData
POSDIR=${RESDIR}/Posteriors
KEYFILE=${RESDIR}/referenceKeys_posteriors.npy

echo "Running Lung Segmentation. Destination folder $DESTLUNG"
echo "-------------------------------------------------------"

mkdir -p $DESTAIR
mkdir -p $DESTLUNG
mkdir -p $DESTIMG
mkdir -p $SEGDIR
mkdir -p "${OUTPUTFOLDER}"
mkdir -p /temp_work/processing/Airways

echo "Converting slices into volume..."
CALL="volume_maker ${INPUT_DIR} $DESTIMG -manual_name ${VOL_FILE}"
echo "$CALL"
eval $CALL

if [ $? -eq 1 ]
then
  echo "Failed to create DICOM volume" >> "$LOGFILE"
  rm -r $DATADIR
  rm -r $RESDIR
  rm -r $SEGDIR
  echo "${VOL_NO_EXTENSION} failed." >> "$LOGFILE"
  exit $?
else
  echo "SUCCESS CREATING DICOM VOLUME"
fi

INPUTFILE="${DESTIMG}/${VOL_FILE}"
cp $INPUTFILE ${OUTPUTFOLDER}

cd /temp_work || exit

CALL="lung_segmentation --verbose true --source $INPUTFILE --scan bottom --skip_distance 10 --min_intensity -1048 --airway_threshold -800 --savepath $DESTLUNG"
echo "$CALL" >> "$LOGFILE"
eval $CALL >> $LOGFILE
mv $DESTLUNG/*-airways.dcm $DESTAIR/

if [ $? -eq 1 ]
then
  echo "${VOL_NO_EXTENSION} failed." >> "$LOGFILE"
  echo "Failed opfront"
  rm -r ${DATADIR}
  rm -r ${SEGDIR}
  rm -r ${RESDIR}
else
  CALL="measure_volume -s $DESTLUNG/*.dcm -v $INPUTFILE >> $OUTPUTFOLDER/lung_volume.txt"
  mkdir -p ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_initial/
  cp -r ${DESTLUNG}/* ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_initial/
  cp -r ${DESTAIR}/* ${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_initial/
fi


echo '-------------------------'
echo 'CLEAN UP.................'
echo '-------------------------'

rm -r ${DATADIR}
rm -r ${SEGDIR}