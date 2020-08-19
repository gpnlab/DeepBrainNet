#!/bin/bash
#
# # RPP.sh
#
# ## Description
#
# This script implements the Registration-based Processng Pipeline (RPP) referred to in the
# README.md file
#
# The primary purposes of the RPP are:
#
# 1. To average any image repeats (i.e. multiple T1w images available)
# 2. To provide an initial robust brain extraction
# 3. To register the subject's native space to the MNI space
#
# ## Prerequisites:
#
# ### Installed Software
#
# * [FSL][FSL] - FMRIB's Software Library (version 5.0.6)
#
# ### Environment Variables
#
# * RPPDIR
#
# * RPP_Scripts
#
#   Location of RPP sub-scripts that are used to carry out some of steps of the RPP.
#
# * FSLDIR
#
#   Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
#   University
#
# ### Image Files
#
# At least one T1 weighted image is required for this script to work.
#
# ### Output Directories
#
# Command line arguments are used to specify the studyFolder (--studyFolder) and
# the subject (--subject).  All outputs are generated within the tree rooted
# at ${studyFolder}/${subject}.  The main output directories are:
#
# * The t1wFolder: ${DBNDir}/data/interim/${studyFolder}/${subject}/{b0}/t1w
# * The atlasSpaceFolder: ${studyFolder}/${subject}/${b0}/MNINonLinear
#
# All outputs are generated in directories at or below these two main
# output directories.  The full list of output directories is:
#
# * ${t1wFolder}/AverageT1wImages
# * ${t1wFolder}/ACPCAlignment
# * ${t1wFolder}/BrainExtractionFNIRTbased
# * ${t1wFolder}/xfms - transformation matrices and warp fields
#
# * ${atlasSpaceFolder}
# * ${atlasSpaceFolder}/xfms
#
# Note that no assumptions are made about the input paths with respect to the
# output directories. All specification of input files is done via command
# line arguments specified when this script is invoked.
#
# Also note that the following output directory is created:
#
# * t1wFolder, which is created by concatenating the following four option
#   values: --studyFolder / --subject / --b0 / --t1
#
# ### Output Files
#
# * t1wFolder Contents: TODO
# * atlasSpaceFolder Contents: TODO
#
# <!-- References -->
# [FSL]: http://fsl.fmrib.ox.ac.uk
#
# ------------------------------------------------------------------------------
#  Code Start
# ------------------------------------------------------------------------------

# Setup this script such that if any command exits with a non-zero value, the
# script itself exits and does not attempt any further processing.
set -e

# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------

script_name=$(basename "${0}")

if [ -z "${DBNDIR}" ]; then
	echo "${script_name}: ABORTING: DBNDIR environment variable must be set"
	exit 1
#else
	#echo "${script_name}: DBNDIR: ${DBNDIR}"
fi

if [ -z "${RPPDIR}" ]; then
	echo "${script_name}: ABORTING: RPPDIR environment variable must be set"
	exit 1
#else
	#echo "${script_name}: RPPDIR: ${RPPDIR}"
fi

if [ -z "${RPP_Libraries}" ]; then
	echo "${script_name}: ABORTING: RPP_Libraries environment variable must be set"
	exit 1
#else
	#echo "${script_name}: RPP_Libraries: ${RPP_Libraries}"
fi

if [ -z "${RPP_Scripts}" ]; then
	echo "${script_name}: ABORTING: RPP_Scripts environment variable must be set"
	exit 1
#else
	#echo "${script_name}: RPP_Scripts: ${RPP_Scripts}"
fi

if [ -z "${FSLDIR}" ]; then
	echo "${script_name}: ABORTING: FSLDIR environment variable must be set"
	exit 1
#else
	#echo "${script_name}: FSLDIR: ${FSLDIR}"
fi


# ------------------------------------------------------------------------------
#  Load Function Libraries
# ------------------------------------------------------------------------------

source ${RPP_Libraries}/log.shlib  # Logging related functions
source ${RPP_Libraries}/opts.shlib # Command line option functions

# ------------------------------------------------------------------------------
#  Usage Description Function
# ------------------------------------------------------------------------------

show_usage() {
	cat <<EOF

RPP.sh

Usage: RPP.sh [options]

  --studyFolder=<studyName>         Name of study data folder (required)
					                Used with --subject input to create full path to root
					                directory for all outputs generated as studyFolder/subject
  --subject=<subject>  Subject ID (required)
					   Used with --studyFolder input to create full path to root
					   directory for all outputs generated as studyFolder/subject
  --b0=<b0>                         Magniture of the B0 field
  --t1=<T1w images>    An @ symbol separated list of full paths to T1-weighted
					   (T1w) structural images for the subject (required)
  --t1Template=<file path>          MNI T1w template
  --t1TemplateBrain=<file path>     Brain extracted MNI T1wTemplate
  --t1Template2mm=<file path>       MNI 2mm T1wTemplate
  --templateMask=<file path>        Brain mask MNI Template
  --template2mmMask=<file path>     Brain mask MNI 2mm Template
  --brainSize=<size value>          Brain size estimate in mm, 150 for humans
  --FNIRTConfig=<file path>         FNIRT 2mm T1w Configuration file

  --topUpConfig=<file path>      Configuration file for topup or "NONE" if not
								 used
EOF
	exit 1
}

# ------------------------------------------------------------------------------
#  Establish tool name for logging
# ------------------------------------------------------------------------------
log_SetToolName "RPP.sh"

# ------------------------------------------------------------------------------
#  Parse Command Line Options
# ------------------------------------------------------------------------------

opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
	show_usage
fi

log_Msg "Platform Information Follows: "
uname -a

echo -e "\nParsing Command Line Opts"
studyFolder=`opts_GetOpt1 "--studyFolder" $@`
subject=`opts_GetOpt1 "--subject" $@`
b0=`opts_GetOpt1 "--b0" $@`
t1wInputImages=`opts_GetOpt1 "--t1" $@`
t1wTemplate=`opts_GetOpt1 "--t1Template" $@`
t1wTemplateBrain=`opts_GetOpt1 "--t1TemplateBrain" $@`
t1wTemplate2mm=`opts_GetOpt1 "--t1Template2mm" $@`
templateMask=`opts_GetOpt1 "--templateMask" $@`
template2mmMask=`opts_GetOpt1 "--template2mmMask" $@`
brainSize=`opts_GetOpt1 "--brainSize" $@`
FNIRTConfig=`opts_GetOpt1 "--FNIRTConfig" $@`

# Use --printcom=echo for just printing everything and not actually
# running the commands (the default is to actually run the commands)
RUN=`opts_GetOpt1 "--printcom" $@`

# ------------------------------------------------------------------------------
#  Show Command Line Options
# ------------------------------------------------------------------------------

log_Msg "studyFolder: ${studyFolder}"
log_Msg "subject: ${subject}"
log_Msg "b0: ${subject}"
log_Msg "t1wInputImages: ${t1wInputImages}"
log_Msg "t1wTemplate: ${t1wTemplate}"
log_Msg "t1wTemplateBrain: ${t1wTemplateBrain}"
log_Msg "t1wTemplate2mm: ${t1wTemplate2mm}"
log_Msg "templateMask: ${templateMask}"
log_Msg "template2mmMask: ${template2mmMask}"
log_Msg "brainSize: ${brainSize}"
log_Msg "FNIRTConfig: ${FNIRTConfig}"
log_Msg "Finished Parsing Command Line Options"

# ------------------------------------------------------------------------------
#  Show Environment Variables
# ------------------------------------------------------------------------------
echo -e "\nEnvironment Variables"
log_Msg "FSLDIR: ${FSLDIR}"
log_Msg "DBNDIR: ${DBNDIR}"
log_Msg "RPPDIR: ${RPPDIR}"

# Naming Conventions
t1wImage="T1w"
t1wFolder="T1w" #Location of T1w images
atlasSpaceFolder="MNINonLinear"

# Build Paths
t1wFolder=${DBNDIR}/data/preprocessed/${studyFolder}/RPP/${subject}/${b0}/${t1wFolder}
atlasSpaceFolder=${DBNDIR}/data/preprocessed/${studyFolder}/RPP/${subject}/${b0}/${atlasSpaceFolder}

log_Msg "t1wFolder: $t1wFolder"
log_Msg "atlasSpaceFolder: $atlasSpaceFolder"

# Unpack List of Images
t1wInputImages=`echo ${t1wInputImages} | sed 's/@/ /g'`

if [ ! -e ${t1wFolder}/xfms ] ; then
	log_Msg "mkdir -p ${t1wFolder}/xfms/"
	mkdir -p ${t1wFolder}/xfms/
fi

if [ ! -e ${atlasSpaceFolder}/xfms ] ; then
	log_Msg "mkdir -p ${atlasSpaceFolder}/xfms/"
	mkdir -p ${atlasSpaceFolder}/xfms/
fi

# ------------------------------------------------------------------------------
#  Do primary work
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#  Loop over the processing for T1w and perform
#  - Average T1w images (if more than one is available)
#  - Rigidly align T1w images to MNI Template to create native volume space
#  - Perform Brain Extraction (FNIRT-based Masking)
# ------------------------------------------------------------------------------

# set up appropriate input variables
t1wInputImages="${t1wInputImages}"
t1wFolder=${t1wFolder}
t1wImage=${t1wImage}
t1wTemplate=${t1wTemplate}
t1wTemplate2mm=${t1wTemplate2mm}

outputT1wImageString=""

i=1
for image in $t1wInputImages ; do
    # reorient $image to mach the orientation of MNI152
    ${RUN} ${FSLDIR}/bin/fslreorient2std $image ${t1wFolder}/${t1wImage}${i}_gdc
	# always add the message/parameters specified
    outputT1wImageString="${outputT1wImageString}${t1wFolder}/${t1wImage}${i}_gdc "
    i=$(($i+1))
done

# Average T1w Scans
echo -e "\n...Averaging T1w Scans"

if [ `echo $t1wInputImages | wc -w` -gt 1 ] ; then
    log_Msg "Averaging ${t1w} Images, performing simple averaging"
    log_Msg "mkdir -p ${t1wFolder}/AverageT1wImages"
    mkdir -p ${t1wFolder}/AverageT1wImages
    ${RUN} ${RPP_Scripts}/AnatomicalAverage.sh -o ${t1wFolder}/${t1wImage} -s ${t1wTemplate} -m ${templateMask} -n -w ${t1wFolder}/AverageT1wImages --noclean -v -b $brainSize $outputT1wImageString
else
    log_Msg "Only one image found, not averaging T1w images, just copying"
    ${RUN} ${FSLDIR}/bin/imcp ${t1wFolder}/${t1wImage}1_gdc ${t1wFolder}/${t1wImage}
fi

# ACPC align T1w image to specified MNI Template to create native volume space
echo -e "\n...Aligning T1w image to ${t1wTemplate} to create native volume space"
log_Msg "mkdir -p ${t1wFolder}/ACPCAlignment"
mkdir -p ${t1wFolder}/ACPCAlignment
${RUN} ${RPP_Scripts}/ACPCAlignment.sh \
    --workingDir=${t1wFolder}/ACPCAlignment \
    --in=${t1wFolder}/${t1wImage} \
    --ref=${t1wTemplate} \
    --out=${t1wFolder}/${t1wImage}_acpc \
    --oMat=${t1wFolder}/xfms/acpc.mat \
    --brainSize=${brainSize}

# Brain Extraction (FNIRT-based Masking)
echo -e "\n...Performing Brain Extraction using FNIRT-based Masking"
log_Msg "mkdir -p ${t1wFolder}/BrainExtractionFNIRTbased"
mkdir -p ${t1wFolder}/BrainExtractionFNIRTbased
${RUN} ${RPP_Scripts}/BrainExtractionFNIRTbased.sh \
    --workingDir=${t1wFolder}/BrainExtractionFNIRTbased \
    --in=${t1wFolder}/${t1wImage}_acpc \
    --ref=${t1wTemplate} \
    --refMask=${templateMask} \
    --ref2mm=${t1wTemplate2mm} \
    --ref2mmMask=${template2mmMask} \
    --outBrain=${t1wFolder}/${t1wImage}_acpc_brain \
    --outBrainMask=${t1wFolder}/${t1wImage}_acpc_brain_mask \
    --FNIRTConfig=${FNIRTConfig}


# ------------------------------------------------------------------------------
# Create a one-step resampled version of the t1w_acpc outputs
# ------------------------------------------------------------------------------

echo -e "\n...Creating one-step resampled version of the T1w_acpc output"

# T1w
${RUN} ${FSLDIR}/bin/fslmerge -t ${t1wFolder}/xfms/${t1wImage} ${t1wFolder}/${t1wImage}_acpc ${t1wFolder}/${t1wImage}_acpc ${t1wFolder}/${t1wImage}_acpc
${RUN} ${FSLDIR}/bin/fslmaths ${t1wFolder}/xfms/${t1wImage} -mul 0 ${t1wFolder}/xfms/${t1wImage}
outputOrigT1w2T1w=origT1w2T1w  # Name for one-step resample warpfield
${RUN} convertwarp --relout --rel --ref=${t1wTemplate} --premat=${t1wFolder}/xfms/acpc.mat --warp1=${t1wFolder}/xfms/${t1wImage} --out=${t1wFolder}/xfms/${outputOrigT1w2T1w}

outputT1wImage=${t1wFolder}/${t1wImage}_acpc
${RUN} applywarp --rel --interp=spline -i ${t1wFolder}/${t1wImage} -r ${t1wTemplate} -w ${t1wFolder}/xfms/${outputOrigT1w2T1w} -o ${outputT1wImage}

# Use -abs (rather than '-thr 0') to avoid introducing zeros
${RUN} fslmaths ${outputT1wImage} -abs ${outputT1wImage} -odt float
${RUN} fslmaths ${outputT1wImage} -mas ${t1wFolder}/${t1wImage}_acpc_brain ${outputT1wImage}_brain

# ------------------------------------------------------------------------------
#  Atlas Registration to MNI152: FLIRT + FNIRT
#  Also applies the MNI registration to T1w image
#  (although, these will be overwritten, and the final versions generated via
#  a one-step resampling equivalent in PostFreeSurfer/CreateMyelinMaps.sh;
#  so, the primary purpose of the following is to generate the Atlas Registration itself).
# ------------------------------------------------------------------------------

echo -e "\n...Performing Atlas Registration to MNI152 (FLIRT and FNIRT)"

${RUN} ${RPP_Scripts}/AtlasRegistrationToMNI152FLIRTandFNIRT.sh \
	--workingDir=${atlasSpaceFolder} \
	--t1=${t1wFolder}/${t1wImage}_acpc \
	--t1Brain=${t1wFolder}/${t1wImage}_acpc_brain \
	--ref=${t1wTemplate} \
	--refBrain=${t1wTemplateBrain} \
	--refMask=${templateMask} \
	--ref2mm=${t1wTemplate2mm} \
	--ref2mmMask=${template2mmMask} \
	--oWarp=${atlasSpaceFolder}/xfms/acpc2standard.nii.gz \
	--oInvWarp=${atlasSpaceFolder}/xfms/standard2acpc_dc.nii.gz \
	--oT1=${atlasSpaceFolder}/${t1wImage} \
	--oT1Brain=${atlasSpaceFolder}/${t1wImage}_brain \
	--FNIRTConfig=${FNIRTConfig}

echo -e "\nMNINonLinear Completed"
