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
#
# ### Environment variables
#
# Should be set in script file pointed to by environmentScript variable.
# See setting of the environmentScript variable in the main() function
# below.
#
# * FSLDIR - main FSL installation directory
# * RPPDIR - main DBN Registration Processing Pipeline (RPP) installation directory
#
# <!-- References -->

###################################################################################
# Function: get_batch_options
# Description
#
#   Retrieve the following command line parameter values if specified
#
#   --studyFolder= - primary study folder containing subject ID subdirectories
#   --subjects=    - quoted, space separated list of subject IDs on which
#                    to run the pipeline
#   --b0=          - Magnitute of the magnetic field used (3T or 7T)
#                    to run the pipeline
#   --runLocal     - if specified (without an argument), processing is run
#                    on "this" machine as opposed to being submitted to a
#                    computing grid
#
#   Set the values of the following global variables to reflect command
#   line specified parameters
#
#   command_line_specified_study_folder
#   command_line_specified_subj_list
#   command_line_specified_b0
#   command_line_specified_run_local
#
#   These values are intended to be used to override any values set
#   directly within this script file
get_batch_options() {
	local arguments=("$@")

	unset command_line_specified_study_folder
	unset command_line_specified_subj
	unset command_line_specified_b0
	unset command_line_specified_run_local
	unset command_line_specified_debug_mode
	unset command_line_specified_linear_mode

	local index=0
	local numArgs=${#arguments[@]}
	local argument

	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--studyFolder=*)
				command_line_specified_study_folder=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subjects=*)
				command_line_specified_subj=${argument#*=}
				index=$(( index + 1 ))
				;;
			--b0=*)
				command_line_specified_b0=${argument#*=}
				index=$(( index + 1 ))
				;;
			--runLocal)
				command_line_specified_run_local="TRUE"
				index=$(( index + 1 ))
				;;
			--debugMode)
				command_line_specified_debug_mode="TRUE"
				index=$(( index + 1 ))
				;;
			--linear)
				command_line_specified_linear_mode="TRUE"
				index=$(( index + 1 ))
				;;
			*)
				echo ""
				echo "ERROR: Unrecognized Option: ${argument}"
				echo ""
				exit 1
				;;
		esac
	done
}

###################################################################################
# Function: main
# Description

#   main processing work of this script
main()
{
	get_batch_options "$@"

	# Set variable values that locate and specify data to process

	# Set up pipeline environment variables and software
    # Get absolute path of setUpRPP.sh
    setup=$( cd "$(dirname "$0")" ; pwd )
    . "${setup}/setUpRPP.sh"
	#. "${PWD}/setUpRPP.sh"
    # Get the root directory; PWD points to ./src/data/RPP
    #DBNDIR="${HOME}/proj/DBN"
    # Get the RPP directory
    #RPPDIR="${DBNDIR}/src/data/RPP"

    # Location of subject folders (named by subjectID)
    studyFolder="${DBNDIR}/data/raw/ADNI"
    studyFolderBasename=`basename $studyFolder`;

    # Space delimited list of subject IDs or file with subject list
    subjects="${DBNDIR}/data/raw/ADNI/subjects.txt"
    # Magnitude of the magnetic field used
    b0="3T"
    # Pipeline environment script
	# environmentScript="${RPPDIR}/setUpRPP.sh"

	# Use any command line specified options to override any of the variables above
	if [ -n "${command_line_specified_study_folder}" ]; then
		studyFolder="${command_line_specified_study_folder}"
	fi

	if [ -n "${command_line_specified_subj}" ]; then
		subjects="${command_line_specified_subj}"
	fi

	if [ -n "${command_line_specified_b0}" ]; then
		b0="${command_line_specified_b0}"
	fi

	if [ -n "${command_line_linear_mode}" ]; then
        echo -e "\nRunning Mode: NonLinear Registration to MNI"
		linear="no"
    else
        echo -e "\nRunning Mode: Linear Registration to MNI"
		linear="yes"
	fi

	# If PRINTCOM is not a null or empty string variable, then this script and
    # other scripts that it calls will simply print out the primary commands it
    # otherwise would run. This printing will be done using the command specified
    # in the PRINTCOM variable
	#PRINTCOM=""
    # Establish queuing command based on command line option
    if [ -n "${command_line_specified_debug_mode}" ] ; then
        echo -e "\nRunning in debug mode"
        PRINTCOM="echo"
    else
        PRINTCOM=""
    fi


	# Report major script control variables to user
    echo -e "\nMajor script control variables\n"
	echo "studyFolder: ${studyFolder}"

    # If a file with the subject ID was passed
    if [ -f "${subjects}" ] ; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            subjList="$subjList $line"
        done < "$subjects"
    # Instead a list was passed
    else
        subjList="$subjects"
    fi

	echo "subjList: ${subjList}"
	echo "environmentScript: ${environmentScript}"
	echo "b0: ${b0}"
	echo "Run locally: ${command_line_specified_run_local}"


	# Define processing queue to be used if submitted to job scheduler
	QUEUE="-q long.q"


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

		# Templates

		# Hires T1w MNI template
		T1wTemplate="${MNI_Templates}/MNI152_T1_0.7mm.nii.gz"

		# Hires brain extracted MNI template
		T1wTemplateBrain="${MNI_Templates}/MNI152_T1_0.7mm_brain.nii.gz"

		# Lowres T1w MNI template
		T1wTemplate2mm="${MNI_Templates}/MNI152_T1_2mm.nii.gz"

		# Hires MNI brain mask template
		TemplateMask="${MNI_Templates}/MNI152_T1_0.7mm_brain_mask.nii.gz"

		# Lowres MNI brain mask template
		Template2mmMask="${MNI_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz"

		# Other Config Settings

		# BrainSize in mm, 150 for humans
		BrainSize="150"

		# FNIRT 2mm T1w Config
		FNIRTConfig="${RPP_Config}/T1_2_MNI152_2mm.cnf"

		# Establish queuing command based on command line option
		if [ -n "${command_line_specified_run_local}" ] ; then
			echo -e "\nAbout to run ${RPPDIR}/RPP.sh\n"
			queuing_command=""
		else
			echo -e "\nAbout to use fsl_sub to queue to run ${RPPDIR}/RPP.sh\n"
			queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
		fi

        # Create log folder
        logDir="${DBNDIR}/logs/${studyFolderBasename}/RPP/${subject}/${b0}"
        mkdir -p $logDir

		# Run (or submit to be run) the RPP.sh script
		# with all the specified parameter values

		${queuing_command} "${RPPDIR}/RPP.sh" \
			--studyFolder="$studyFolderBasename" \
			--subject="$subject" \
			--b0="$b0" \
			--t1="$T1wInputImages" \
			--t1Template="$T1wTemplate" \
			--t1TemplateBrain="$T1wTemplateBrain" \
			--t1Template2mm="$T1wTemplate2mm" \
			--templateMask="$TemplateMask" \
			--template2mmMask="$Template2mmMask" \
			--brainSize="$BrainSize" \
            --linear="$linear" \
			--FNIRTConfig="$FNIRTConfig" \
			--printcom=$PRINTCOM \
            &> "$logDir"/"$subject".txt

    done
}

# Invoke the main function to get things started
main "$@"
