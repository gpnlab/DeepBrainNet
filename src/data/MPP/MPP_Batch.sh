#!/bin/bash

# # RPPBatch.sh
#
# ## Description:
# Batch script for running the Registtration-based Preprocessing Pipeline.
#
# ## Prerequisites
#
# ### Installed software
#
# * FSL
# * MATLAB
# * SPM12
#
# ### Environment variables
#
# Should be set in environment configuration script file.
# See setting of ./setUpRPP.sh
# below.
#
# * FSLDIR - main FSL installation directory
# * MATLABDIR - main MATLAB installation directory
# * SPM12DIR - main SPM12 installation directory
# * RPPDIR - main DBN Registration Processing Pipeline (RPP) installation directory
#
# <!-- References -->

set -eu

RSYNC=/usr/bin/rsync

setup=$( cd "$(dirname "$0")" ; pwd )
. "${setup}/setUpRPP.sh"
. "${DBN_Libraries}/newopts.shlib" "$@"

# This function gets called by opts_ParseArguments when --help is specified
function usage() {
    # header text
    echo "
        $log_ToolName: Batch script for running the Registration-based Preprocessing Phase.

        Usage: $log_ToolName --studyFolder=<path to the folder with subject images>
                             --subjects=<file or list of subject IDs>
                             [--b0=<scanner magnetic field intensity] default=3T
                             [--runLocal=<do (not) run locally>] default=yes
                             [--linear=<select (non)linear registered image>] default=yes
                             [--debugMode=<do(non) perform a dry run>] default=yes

        PARAMETERs are [ ] = optional; < > = user supplied value

        Values default to running the example with sample data
    "
    # automatic argument descriptions
    opts_ShowArguments
}

get_subjList() {
    file_or_list=$1
    subjList=""
    # If a file with the subject ID was passed
    if [ -f "$file_or_list" ] ; then
        echo "here"
        while IFS= read -r line || [[ -n "$line" ]]; do
            subjList="$subjList $line"
        done < "$file_or_list"
    # Instead a list was passed
    else
        subjList="$file_or_list"
    fi

    # Sort subject list
    IFS=$'\n' # only word-split on '\n'
    subjList=( $( printf "%s\n" ${subjList[@]} | sort -n) ) # sort
    IFS=$' \t\n' # restore the default
    unset file_or_list
}

function main() {
    opts_AddMandatory '--studyFolder' 'studyFolder' 'raw data folder path' "a required value; is the path to the study folder holding the raw data. Don't forget the study name (e.g. ${DBNDIR}/data/raw/ADNI)"
    opts_AddMandatory '--subjects' 'subjects' 'path to file with subject IDs' "an optional value; path to a file with the IDs of the subject to be processed (e.g. ${DBNDIR}/data/rawe/ADNI/subjects/txt)" "--subject" "--subjectList" "--subjList"
    opts_AddOptional  '--b0' 'b0' 'magnetic field intensity' "an optional value; the scanner magnetic field intensity, e.g., 1.5T, 3T, 7T" "3T"
    opts_AddOptional  '--runLocal' 'runLocal' 'do (not) run locallly' "an optinal value; indicates if processing is run on "this" machine as opposed to being submitted to a computing grid"  "yes"
    opts_AddOptional  '--linear'  'linear' '(non)linear registration to MNI' "an optional value; if it is set then only an affine registration to MNI is performed, otherwise, a nonlinear registration to MNI is performed" "yes"
    opts_AddOptional  '--windowSize'  'WindowSize' 'window size for bias correction' "an optional value; window size for bias correction; for 7T MRI, the optimal value ranges between 20 and 30" "30"
    opts_AddOptional  '--customBrain'  'CustomBrain' 'If custom mask or structural images provided' "an optional value; If you have created a custom brain mask saved as <subject>/T1w/custom_acpc_mask.nii.gz, specify MASK. If you have created custom structural images, e.g.: - <subject>/T1w/T1w_acpc_brain_final.nii.gz - <subject>/T1w/T1w_acpc_final.nii.gz - <subject>/T1w/T2w_acpc_brain_final.nii.gz - <subject>/T1w/T2w_acpc_final.nii.gz to be used when peforming MNI152 Atlas registration, specify CUSTOM. When MASK or CUSTOM is specified, only the AtlasRegistration step is run. If the parameter is omitted or set to NONE (the default), standard image processing will take place. NOTE: This option allows manual correction of brain images in cases when they were not successfully processed and/or masked by the regular use of the pipelines. Before using this option, first ensure that the pipeline arguments used were correct and that templates are a good match to the data." "NONE"
    opts_AddOptional  '--debugMode' 'PRINTCOM' 'do (not) perform a dray run' "an optional value; If PRINTCOM is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the PRINTCOM variable, e.g., echo" "" "--PRINTCOM" "--printcom"

    opts_ParseArguments "$@"

    # Display the parsed/default values
    opts_ShowValues

    # Processing code goes here

    # Location of subject folders (named by subjectID)
    studyFolderBasename=`basename $studyFolder`;

	# Report major script control variables to user
    echo -e "\nMajor script control variables\n"
	echo "studyFolder: ${studyFolder}"
    get_subjList $subjects
	echo "subjList: ${subjList}"
	echo "environmentScript: ${setup}/setUpRPP.sh"
	echo "b0: ${b0}"
	echo "runLocal: ${runLocal}"
	echo "linear: ${linear}"
	echo "debugMode: ${PRINTCOM}"

    ###############################################################################
	# Inputs:
	#
	# Scripts called by this script do NOT assume anything about the form of the
	# input names or paths. This batch script assumes the following raw data naming
	# convention, e.g.
	#
	# ${studyFolder}/${subject}/{b0}/T1w_MPR1/${subject}_{b0}_T1w_MPR1.nii.gz
	# ${studyFolder}/${subject}/{b0}/T1w_MPR2/${subject}_{b0}_T1w_MPR2.nii.gz
    # ...
	# ${studyFolder}/${subject}/{b0}/T1w_MPRn/${subject}_{b0}_T1w_MPRn.nii.gz
    ###############################################################################

	# Do work
    echo -e "\nCycling through subject list\n"
	# Cycle through specified subjects
	for subject in $subjList ; do
		echo -e "Subject $subject"

		# Input Images
		# Detect Number of T1w Images and build list of full paths to T1w images
		numT1ws=`ls ${studyFolder}/${subject}/${b0} | grep 'T1w_MPR.$' | wc -l`
		echo "Found ${numT1ws} T1w Images for subject ${subject}"
		T1wInputImages=""
		i=1
		while [ $i -le $numT1ws ] ; do
            # An @ symbol separate the T1-weighted image's full paths
			T1wInputImages=`echo "${T1wInputImages}${studyFolder}/${subject}/${b0}/T1w_MPR${i}/${subject}_${b0}_T1w_MPR${i}.nii.gz@"`
			i=$(($i+1))
		done

		# Detect Number of T2w Images and build list of full paths to T2w images
		numT2ws=`ls ${studyFolder}/${subject}/${b0} | grep 'T2w_SPC.$' | wc -l`
		echo "Found ${numT2ws} T2w Images for subject ${subject}"
		T2wInputImages=""
		i=1
		while [ $i -le $numT2ws ] ; do
            # An @ symbol separate the T2-weighted image's full paths
			T2wInputImages=`echo "${T2wInputImages}${studyFolder}/${subject}/${b0}/T2w_SPC${i}/${subject}_${b0}_T2w_SPC${i}.nii.gz@"`
			i=$(($i+1))
		done

		# Templates

		# Hires T1w MNI template
		T1wTemplate="${MNI_Templates}/MNI152_T1_0.7mm.nii.gz"
		# Hires brain extracted MNI template
		T1wTemplateBrain="${MNI_Templates}/MNI152_T1_0.7mm_brain.nii.gz"
		# Lowres T1w MNI template
		T1wTemplate2mm="${MNI_Templates}/MNI152_T1_2mm.nii.gz"
		# Hires T2w MNI template
		T2wTemplate="${MNI_Templates}/MNI152_T2_0.7mm.nii.gz"
		# Hires brain extracted MNI template
		T2wTemplateBrain="${MNI_Templates}/MNI152_T2_0.7mm_brain.nii.gz"
		# Lowres T1w MNI template
		T2wTemplate2mm="${MNI_Templates}/MNI152_T2_2mm.nii.gz"
		# Hires T1w MNI brain mask template
		TemplateMask="${MNI_Templates}/MNI152_T1_0.7mm_brain_mask.nii.gz"
		# Lowres T1w MNI brain mask template
		Template2mmMask="${MNI_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz"

		# Other Config Settings

		# BrainSize in mm, 150 for humans
		BrainSize="150"

		# FNIRT 2mm T1w Config
		FNIRTConfig="${RPP_Config}/T1_2_MNI152_2mm.cnf"

        # Create log folder
        logDir="${DBNDIR}/logs/${studyFolderBasename}/RPP/${subject}/${b0}"
        mkdir -p $logDir

		# Establish queuing command based on command line option
		if [ $runLocal = yes ] ; then
			echo -e "\nAbout to run ${RPPDIR}/RPP.sh\n"
			queuing_command="nohup"

            # Run (or submit to be run) the RPP.sh script
            # with all the specified parameter values
            ${queuing_command} "${RPPDIR}/RPP.sh" \
                --studyName="$studyFolderBasename" \
                --subject="$subject" \
                --b0="$b0" \
                --t1="$T1wInputImages" \
                --t2="$T2wInputImages" \
                --t1Template="$T1wTemplate" \
                --t1TemplateBrain="$T1wTemplateBrain" \
                --t1Template2mm="$T1wTemplate2mm" \
                --t2Template="$T2wTemplate" \
                --t2TemplateBrain="$T2wTemplateBrain" \
                --t2Template2mm="$T2wTemplate2mm" \
                --templateMask="$TemplateMask" \
                --template2mmMask="$Template2mmMask" \
                --brainSize="$BrainSize" \
                --linear="$linear" \
                --windowSize="$WindowSize" \
                --customBrain="$CustomBrain" \
                --FNIRTConfig="$FNIRTConfig" \
                --printcom=$PRINTCOM \
                1> "$logDir"/"$subject".out \
                2> "$logDir"/"$subject".err
		else
			echo -e "\nAbout to use sbatch to run ${RPPDIR}/RPP.sh\n"
            QUEUE="--partition=workstation"
			queuing_command="sbatch --requeue --export=ALL --job-name=RPP_${subject} --mail-user=eduardojdiniz@gmail.com --mail-type=FAIL,END --ntasks-per-node=1 --mem=4gb --output=${logDir}/${subject}.txt --error=${logDir}/${subject}.txt ${QUEUE}"

            # Run (or submit to be run) the RPP.sh script
            # with all the specified parameter values
            ${queuing_command} "${RPPDIR}/RPP.sh" \
                --studyName="$studyFolderBasename" \
                --subject="$subject" \
                --b0="$b0" \
                --t1="$T1wInputImages" \
                --t2="$T2wInputImages" \
                --t1Template="$T1wTemplate" \
                --t1TemplateBrain="$T1wTemplateBrain" \
                --t1Template2mm="$T1wTemplate2mm" \
                --t2Template="$T2wTemplate" \
                --t2TemplateBrain="$T2wTemplateBrain" \
                --t2Template2mm="$T2wTemplate2mm" \
                --templateMask="$TemplateMask" \
                --template2mmMask="$Template2mmMask" \
                --brainSize="$BrainSize" \
                --linear="$linear" \
                --windowSize="$windowSize"
                --FNIRTConfig="$FNIRTConfig" \
                --printcom=$PRINTCOM
		fi

        # Transfer the preprocessed data to the permanent directory
        tmpDir="$(dirname "$0")"/tmp/${studyFolderBasename}/preprocessed/
        $RSYNC -r $tmpDir ${DBNDIR}/data/preprocessed/${studyFolderBasename}
        # Remove temporary directory
        rm -r "$(dirname "$0")"/tmp

    done
}

main "$@"
