#!/bin/bash

set -eu

#source "${PWD}/setUpApp.sh"
. "${PWD}/src/app/setUpApp.sh"
#source "${DBN_Libraries}/newopts.shlib" "$@"
. "${DBN_Libraries}/newopts.shlib" "$@"

#this function gets called by opts_ParseArguments when --help is specified
function usage()
{
    #header text
    echo "
$log_ToolName: Predict brain age given a brain extracted, MNI registered T1w Image

Usage: $log_ToolName --data=<path to the data folder>
                     --subjects=<path to file with subject IDs>
                     --output=<path to outuput txt file>
                     [--b0=<scanner magnetic field intensity] default=3T
                     [--model=<path to the .h5 neural network model] default="${DBNDIR}/models/DBN_model.h5"

PARAMETERs are [ ] = optional; < > = user supplied value

Values default to running the example with sample data
"
    #automatic argument descriptions
    opts_ShowArguments
}

function main()
{
    opts_AddMandatory '--data' 'DATA_FOLDER' 'data folder Path' "a required value; is the path to the study folder holding the preprocessed data" "--dataFolder"
    opts_AddOptional  '--subjects' 'SUBJECTS' 'path to file with subject IDs' "an optional value; path to a file with the IDs of the subject to be processed" "default"  "--subject" "--subjectList" "--subjList"
    opts_AddOptional  '--output' 'OUT_FILE' 'path to output file' "an optional value; the output txt file that will hold the brain age predictions" "default"  "--out"
    opts_AddOptional  '--b0' 'B0' 'magnetic field intensity' "an optional value; the scanner magnetic field intensity, e.g., 1.5T, 3T, 7T" "3T"
    opts_AddOptional  '--model' 'MODEL' 'path to .h5 model' "an optional value; path to the model.h5 file" "${DBNDIR}/models/DBN_model.h5"
    opts_ParseArguments "$@"

    #display the parsed/default values
    opts_ShowValues

    #processing code goes here

    ### Inputs
    #
    # Scripts called by this script do NOT assume anything about the form of the input names or paths.
    # This batch script assumes the following preprocessed data namimg convention, e.g.
    # ${STUDY}/${PIPELINE}/{SUBJECT}/{B0}/MNINonLinear/T1w_brain.nii.gz
    ###

    ### Extract T1w from subject directories and add to a single directory
    # Predict brain age and save in output .txt file
    if [ "$SUBJECTS" = "default" ] ; then
        #SUBJECTS="${DATA_FOLDER}/${STUDY_NAME}/${PIPELINE}/subjects.txt"
        SUBJECTS="${DATA_FOLDER}/subjects.txt"
    fi

    # Read SUBJECTS file
    subjList=""
    if [ -f "${SUBJECTS}" ] ; then
        while IFS= read -r line || [[ -n "$line" ]] ; do
            subjList="$subjList $line"
        done < "$SUBJECTS"
    else
        echo ""
        echo "ERROR: ${SUBJECTS} is not a file"
        echo ""
        exit 1
    fi

    subjListFilename=$(basename -- "${SUBJECTS}")
    subjListFilename="${subjListFilename%.*}"
    #subjListFilename="${SUBJECTS##*/}"
    #SUBJECTS_DIR="${DATA_FOLDER}/${STUDY_NAME}/${PIPELINE}/${subjListFilename}"
    SUBJECTS_DIR="${DATA_FOLDER}/${subjListFilename}"
    mkdir -p $SUBJECTS_DIR
    echo -e "\nCycling through list of subjects\n"
    for subject in $subjList ; do
        echo -e "Subject $subject"
        #subjectImage="${DATA_FOLDER}/${STUDY_NAME}/${PIPELINE}/${subject}/${B0}/MNINonLinear/T1w_brain.nii.gz"
        subjectImage="${DATA_FOLDER}/${subject}/${B0}/MNINonLinear/T1w_brain.nii.gz"
        cp $subjectImage "${SUBJECTS_DIR}/${subject}_${B0}_T1w_brain.nii.gz"
    done

    # Slice T1w and save slices as .jpg in a Test folder
    IMAGES_DIR="${SUBJECTS_DIR}/Test"
    mkdir -p $IMAGES_DIR
    rsync $SUBJECTS $SUBJECTS_DIR/$subjListFilename
    python $DBNDIR/src/data/slicer.py ${SUBJECTS_DIR}/ ${IMAGES_DIR}/

    # Predict brain age and save in output .txt file
    if [ "$OUT_FILE" = "default" ] ; then
        OUT_FILE="$SUBJECTS_DIR/brain_ages.txt"
    fi

    mkdir -p "${OUT_FILE%/*}"
    python $DBNDIR/src/app/pred.py $SUBJECTS_DIR $SUBJECTS $MODEL $OUT_FILE
    rsync $OUT_FILE $SUBJECTS_DIR/brain_ages.txt
}

if (($# == 0)) || [[ "$1" == --* ]]
then
    #named parameters
    main "$@"
else
    #positional support goes here - just call main with named parameters built from $1, etc
    log_Err_Abort "positional parameter support is not currently implemented"
    main --data="$1" --study="$2" --pipeline="$3" --output="$4" --b0="$5" --model="$6"
fi
