#!/bin/bash

set -eu

# Requirements for this script
#  installed versions of: MATLAB, SPM12
#  environment: SPM12DIR, MATLABDIR, DBN_Libraries, RPP_Scripts


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

if [ -z "${RPP_Scripts}" ]; then
	echo "$(basename ${0}): ABORTING: RPP_Scripts environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): RPP_Scripts: ${RPP_Scripts}"
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
    opts_AddMandatory '--image' 'InputImage' 'Input Image' "a required value; input image"
    opts_AddOptional '--windowSize' 'windowSize' 'size of the window' "an optional value; size of the window; 7T MRI usually uses smaller window. Between 20 and 30 should give good results." "30"
    opts_AddMandatory '--output' 'OutputImage' 'Bias corrected image' "a required value; Bias corrected image"
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

    cp $InputImage "$WD"
    gzip -d "$WD"/$InputImage

    ${MATLABDIR} -nodesktop -nosplash -r "addpath('${RPP_Scripts}'); BiasCorrection('"$WD"/$Basename.nii', '$SPM12DIR', '$windowSize'); exit"

    gzip "$WD"/m$BaseName.nii
    mv "$WD"/m$Basename.nii.gz $OutputImage
    rm "$WD"/$InputImage

