#!/bin/bash

# Pipe through a DICOM volume and obtain the airway segmentation from it.

INPUT_DIR=${1}
VOL_FILE=${2}
VOL_NO_EXTENSION="${VOL_FILE%.*}"
OUTPUTFOLDER=${3}
LOGFILE=${4:-$OUTPUTFOLDER/${VOL_NO_EXTENSION}_LOG.log}

echo "Input File: ${VOL_FILE}"
echo "Output Folder: ${3}"

DATADIR=/temp_work/processing
DESTIMG=${DATADIR}/RAW/DICOM

mkdir -p $DESTIMG
mkdir -p "${OUTPUTFOLDER}"

if [ -z "$(ls -A $DESTIMG)" ]; then
    echo "Converting slices into volume..."
    CALL="volume_maker ${INPUT_DIR} $DESTIMG -manual_name ${VOL_FILE}"
    echo "$CALL"
    eval "$CALL"
else
    echo "Volume Exists"
fi

if [ $? -eq 1 ]
then
  echo "Failed to create DICOM volume"
  rm -r $DATADIR
  echo "${VOL_NO_EXTENSION} failed to make volume." >> "$LOGFILE"
  exit $?
else
  echo "SUCCESS CREATING DICOM VOLUME"
fi

INPUTFILE="${DESTIMG}/${VOL_FILE}"
# cp "$INPUTFILE" "${OUTPUTFOLDER}"


function pwait() {
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}

function run_segmentation() {
    DEST_RES=${OUTPUTFOLDER}/${VOL_NO_EXTENSION}_$1_$2
    DEST_FILE=$1_$2.dcm
    mkdir -p ${DEST_RES}
    ln -s $INPUTFILE $DEST_FILE
    CALL="lung_segmentation --verbose false --source $DEST_FILE --skip_distance $1 --min_intensity -1048 --airway_threshold -$2 --scan bottom --savepath $DEST_RES"
    echo "$CALL"
    eval "$CALL"
    if [ $? -eq 1 ]; then
        echo "${VOL_NO_EXTENSION} failed." >> "$LOGFILE"
        echo "$1,$2" >> "$LOGFILE"
        echo "Failed lung segmentation +/- airway segmentation."
    else
        echo "Lung Segmentation Success"
        rm $DEST_RES/*.dcm
    fi
}


    for skip_distance in 20 30 40 50 60
    do
        for threshold in 860 855 850 845 840 835 830
        do
            run_segmentation $skip_distance $threshold &
            pwait 10
        done
    done

echo "DONE OPTIMISATION" >> "$LOGFILE"
