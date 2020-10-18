#!/bin/bash

set -eu

# Requirements for this script
#  installed versions of: MATLAB, SPM12
#  environment: SPM12DIR, MATLABDIR, DBN_Libraries, MPP_Scripts


# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------

if [ -z "${MATLABDIR}" ]; then
	echo "$(basename ${0}): ABORTING: MATLABDIR environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): MATLABDIR: ${MATLABDIR}"
fi

if [ -z "${SPM12DIR}" ]; then
	echo "$(basename ${0}): ABORTING: SPM12DIR environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): SPM12DIR: ${SPM12DIR}"
fi

if [ -z "${MPP_Scripts}" ]; then
	echo "$(basename ${0}): ABORTING: MPP_Scripts environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): MPP_Scripts: ${MPP_Scripts}"
fi

if [ -z "${DBN_Libraries}" ]; then
	echo "$(basename ${0}): ABORTING: DBN_Libraries environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): DBN_Libraries: ${DBN_Libraries}"
fi

################################################ SUPPORT FUNCTIONS ##################################################

. "${DBN_Libraries}/newopts.shlib" "$@"
. "${DBN_Libraries}/log.shlib" # Logging related functions

#this function gets called by opts_ParseArguments when --help is specified
function usage()
{
    #header text
    echo "
$log_ToolName: Perform Bias Correction

Usage: $log_ToolName --workingDir=<path to the working directory>
                     --image=<path to nii file>
                     [--windowSize=<size of window>] default=30
                     --output=<path to the bias corrected image>

PARAMETERs are [ ] = optional; < > = user supplied value

Values default to running the example with sample data
"
    #automatic argument descriptions
    opts_ShowArguments
}

function main()
{
    opts_AddOptional '--workingDir' 'WD' 'Working Directory' "an optional value; directory to save byproducts" "."
    opts_AddMandatory '--segmentationDir' 'SD' 'Segmentation Directory' "a required value; directory with segmentation contrasts"
    opts_AddMandatory '--in' 'InputImage' 'Input Image' "a required value; input image"
    opts_AddMandatory '--outImage' 'OutputImage' 'Bias corrected image' "a required value; Bias corrected image"
    opts_AddMandatory '--outBrain' 'OutputBrain' 'Bias corrected image' "a required value; Bias corrected image"
    opts_AddMandatory '--outBrainMask' 'OutputBrainMask' 'Bias corrected image' "a required value; Bias corrected image"
    opts_ParseArguments "$@"

    #display the parsed/default values
    opts_ShowValues

    mkdir -p $WD

    # Record the input options in a log file
    echo "$0 $@" >> $WD/log.txt
    echo "PWD = `pwd`" >> $WD/log.txt
    echo "date: `date`" >> $WD/log.txt
    echo " " >> $WD/log.txt

    # ------------------------------------------------------------------------------
    # Create a Bias Corrected Version of the Input
    # ------------------------------------------------------------------------------

    log_Msg "START: Brain Extraction Segmentation-based"

    BaseName=`${FSLDIR}/bin/remove_ext $InputImage`;
    BaseName=`basename $BaseName`;

    $FSLDIR/bin/imcp $InputImage "$WD"/$BaseName
    gzip -d "$WD"/$BaseName.nii.gz

    ${MATLABDIR} -nodesktop -nosplash -r "addpath('${MPP_Scripts}'); BrainExtractionSegmentationBased('$SPM12DIR', '"$WD"', '"$BaseName"'); exit"

    gzip "$WD"/brain_mask_$BaseName.nii

    ${FSLDIR}/bin/fslmaths "$InputImage" -mas "$WD"/brain_mask_$BaseName.nii.gz "$OutputBrain"

    ${FSLDIR}/bin/fslmaths "$OutputBrain" -abs "$OutputBrain" -odt float

    #${FSLDIR}/bin/imcp $InputImage $OutputImage

    ${FSLDIR}/bin/imcp "$WD"/brain_mask_$BaseName.nii.gz $OutputBrainMask

    rm "$WD"/$BaseName.nii
    rm "$WD"/brain_mask_$BaseName.nii.gz
    rm "$WD"/m$BaseName.nii

    log_Msg "END: Brain Extraction Segmentation-based"

    # ------------------------------------------------------------------------------
    # QA STUFF
    # ------------------------------------------------------------------------------
    echo " END: `date`" >> $WD/log.txt

    if [ -e $WD/qa.txt ] ; then rm -f $WD/qa.txt ; fi
    echo "cd `pwd`" >> $WD/qa.txt
    echo "# Check quality of alignment with MNI image" >> $WD/qa.txt
    echo "fsleyes ${InputImage} ${OutputImage}" >> $WD/qa.txt
}

main "$@"
