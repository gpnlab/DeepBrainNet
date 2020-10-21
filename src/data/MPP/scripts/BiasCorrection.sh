#!/bin/bash

# ------------------------------------------------------------------------------
#  Code Start
# ------------------------------------------------------------------------------

# Setup this script such that if any command exits with a non-zero value, the
# script itself exits and does not attempt any further processing. Also, treat
# unset variables as an error when substituting.
set -eu

# ------------------------------------------------------------------------------
#  Load Function Libraries
# ------------------------------------------------------------------------------
. "${DBN_Libraries}/newopts.shlib" "$@"
. "${DBN_Libraries}/log.shlib" # Logging related functions

# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------
log_Check_Env_Var MATLABDIR
log_Check_Env_Var SPM12DIR
log_Check_Env_Var MPP_Scripts
log_Check_Env_Var DBN_Libraries

# ------------------------------------------------------------------------------
#  Usage Description Function
# ------------------------------------------------------------------------------
#this function gets called by opts_ParseArguments when --help is specified
function usage()
{
    echo "
$log_ToolName: Perform Bias Correction

Usage: $log_ToolName --workingDir=<path to the working directory>
                     --image=<path to nii file>
                     [--windowSize=<size of window>] default=30
                     --output=<path to the bias corrected image>

PARAMETERs are [ ] = optional; < > = user supplied value

Values default to running the example with sample data
"
    opts_ShowArguments
}

function main()
{
    opts_AddOptional '--workingDir' 'WD' 'Working Directory' "an optional value; directory to save byproducts" "."
    opts_AddMandatory '--inputImage' 'InputImage' 'Input Image' "a required value; input image"
    opts_AddOptional '--windowSize' 'windowSize' 'size of the window' "an optional value; size of the window; 7T MRI usually uses smaller window. Between 20 and 30 should give good results." "30"
    opts_AddMandatory '--outputImage' 'OutputImage' 'Bias corrected image' "a required value; Bias corrected image"
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

    log_Msg "START: Bias correction"

    BaseName=`${FSLDIR}/bin/remove_ext $InputImage`;
    BaseName=`basename $BaseName`;

    $FSLDIR/bin/imcp $InputImage "$WD"/$BaseName
    gzip -d "$WD"/$BaseName.nii.gz

    ${MATLABDIR} -nodesktop -nosplash -r "addpath('${MPP_Scripts}'); BiasCorrection('"$WD"/$BaseName.nii', '$SPM12DIR', '$windowSize'); exit"

    gzip "$WD"/m$BaseName.nii
    $FSLDIR/bin/imcp "$WD"/m$BaseName.nii.gz $OutputImage.nii.gz
    rm "$WD"/$BaseName.nii
    rm "$WD"/m$BaseName.nii.gz

    log_Msg "END: One-set resampled version of T1w_acpc output"

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
