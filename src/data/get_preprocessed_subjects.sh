#!/bin/bash

set -eu

DBNDIR=${HOME}/proj/DBN
. "${DBNDIR}/src/global/libs/newopts.shlib" "$@"

#this function gets called by opts_ParseArguments when --help is specified
function usage()
{
    #header text
    echo "
$log_ToolName: Predict brain age given a brain extracted, MNI registered T1w Image

Usage: $log_ToolName --in_subjects=<path to list of subjects that need to be checked>
                     --log=<path to the directory containing the log files produced by the preprocessing pipeline>
                     [--out_subjects=<path to output file with list of subject IDs that needs preprocessing>]

PARAMETERs are [ ] = optional; < > = user supplied value

Values default to running the example with sample data
"
    #automatic argument descriptions
    opts_ShowArguments
}

function main()
{
    opts_AddMandatory '--in_subjects' 'INPUT_SUBJECTS' 'path to list of subjects' "a required value; is the path to the list of subjects that need to be checked" "--inSubjects"
    #opts_AddMandatory '--in_data' 'INPUT_DATA_FOLDER' 'path to raw data' "a required value; is the path to the study folder holding the raw data" "--inData"
    #opts_AddMandatory '--out_data' 'OUTPUT_DATA_FOLDER' 'path to preprocessed data' "a required value; is the path to the study folder holding the preprocessed data" "--outData"
    opts_AddMandatory '--log' 'LOG_FOLDER' 'path to the log directory' "path to the directory containing the log files produced by the preprocessing pipeline"  "--logDir"
    opts_AddOptional  '--out_subjects' 'OUT_SUBJECTS' 'path to output file with list of subject IDs' "an optional value; path to output file with list of subject IDs that needs preprocessing" "default" "outSubjects"
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


    # Read INPUT_SUBJECTS file
    if [ -f "${INPUT_SUBJECTS}" ] ; then
        notLoggedSubjects=""
        while IFS= read -r line || [[ -n "$line" ]] ; do
            notLoggedSubjects="$notLoggedSubjects $line"
        done < "$INPUT_SUBJECTS"
    else
        echo ""
        echo "ERROR: ${INPUT_SUBJECTS} is not a file"
        echo ""
        exit 1
    fi

    # Write files that have already being processed into LOGGED_SUBJECTS file
    if [ -d "${LOG_FOLDER}" ] ; then
        loggedSubjectsFile="${LOG_FOLDER}/logged_subjects.txt"
        if [ -e "${loggedSubjectsFile}" ] ; then
            rm -f "${loggedSubjectsFile}"
            files=$(grep -l -R "RPP Completed" ${LOG_FOLDER})
            for f in $files ; do
                #filename=$(dirname "$(dirname "$f")")
                #filename=$(basename -- "$filename")
                filename=$(basename -- "$f")
                filename="${filename%.*}"
                echo $filename >> $loggedSubjectsFile
            done
        fi
    else
        echo ""
        echo "ERROR: ${LOG_FOLDER} is not a dir"
        echo ""
        exit 1
    fi

    # Create list of files that need to be processed
    if [ -e ${OUT_SUBJECTS} ] ; then
        rm -f ${OUT_SUBJECTS}
    else
        touch ${OUT_SUBJECTS}
    fi
    while read subject ; do
        echo $subject >> $OUT_SUBJECTS
    done < <(comm -3 <(sort "$INPUT_SUBJECTS") <(sort $loggedSubjectsFile))

}

if (($# == 0)) || [[ "$1" == --* ]]
then
    #named parameters
    main "$@"
else
    #positional support goes here - just call main with named parameters built from $1, etc
    log_Err_Abort "positional parameter support is not currently implemented"
    main --in_subjects="$1" --log="$2" --out_subjects="$3"
fi
