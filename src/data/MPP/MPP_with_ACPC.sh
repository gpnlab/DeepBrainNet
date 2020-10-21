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

# 1. To average any image repeats (i.e. multiple T1w or T2w images available)
# 2. To provide an initial robust brain extraction
# 3. To align the T1w and T2w structural images (register them to the native space)
# 4. To register the subject's native space to the MNI space
#
# ## Prerequisites:
#
# ### Installed Software
#
# * [FSL][FSL] - FMRIB's Software Library (version 5.0.6)
# * MATLAB
# * SPM12
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
# * MATLABDIR
#
#   Home directory for MATLAB from
#
# * SPM12DIR
#
#   Home directory for SPM12 from
#
# ### Image Files
#
# At least one T1 weighted image and one T2 weighted image are required for this
# script to work.
#
# ### Output Directories
#
# Command line arguments are used to specify the studyName (--studyName) and
# the subject (--subject).  All outputs are generated within the tree rooted
# at ./tmp/${studyName}/${subject}.  The main output directories are:
#
# * The t1wFolder: ./tmp/${studyName}/${subject}/{b0}/t1w
# * The t2wFolder: ./tmp/${studyName}/${subject}/{b0}/t2w
# * The atlasSpaceFolder: ./tmp/${studyName}/${subject}/${b0}/MNI(Non)Linear
#
# All outputs are generated in directories at or below these two main
# output directories.  The full list of output directories is:
#
# * ${t1wFolder}/AverageT1wImages
# * ${t1wFolder}/ACPCAlignment
# * ${t1wFolder}/BrainExtractionFNIRTbased
# * ${t1wFolder}/xfms - transformation matrices and warp fields
#
# * ${t2wFolder}/AverageT1wImages
# * ${t2wFolder}/ACPCAlignment
# * ${t2wFolder}/BrainExtractionFNIRTbased
# * ${t2wFolder}/xfms - transformation matrices and warp fields
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
#   values: --studyName / --subject / --b0 / --t1
#
# * t2wFolder, which is created by concatenating the following four option
#   values: --studyName / --subject / --b0 / --t2
#
# ### Output Files
#
# * t1wFolder Contents: TODO
# * t2wFolder Contents: TODO
# * atlasSpaceFolder Contents: TODO
#
# <!-- References -->
# [FSL]: http://fsl.fmrib.ox.ac.uk
#
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

. ${DBN_Libraries}/log.shlib  # Logging related functions
. ${DBN_Libraries}/opts.shlib # Command line option functions

# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------

log_Check_Env_Var DBNDIR
log_Check_Env_Var DBN_Libraries
log_Check_Env_Var RPPDIR
log_Check_Env_Var RPP_Scripts
log_Check_Env_Var FSLDIR
log_Check_Env_Var MATLABDIR
log_Check_Env_Var SPM12DIR

# ------------------------------------------------------------------------------
#  Usage Description Function
# ------------------------------------------------------------------------------

script_name=$(basename "${0}")

show_usage() {
	cat <<EOF

    ${script_name}

    Usage: ${script_name} [options]

  --studyName=<studyName>           Name of study (required)
					                Used with --subject input to create path to
					                directory for all outputs generated as
                                    ./tmp/studyName/subject
  --subject=<subject>               Subject ID (required)
                                    Used with --studyName input to create path to
                                    directory for all outputs generated as
                                    ./tmp/studyName/subject
  --b0=<b0>                         Magniture of the B0 field
  --t1=<T1w images>                 An @ symbol separated list of full paths to
                                    T1-weighted (T1w) structural images for
                                    the subject (required)
  --t2=<T2w images>                 An @ symbol separated list of full paths to
                                    T2-weighted (T2w) structural images for
                                    the subject (required)
  --t1Template=<file path>          MNI T1w template
  --t1TemplateBrain=<file path>     Brain extracted MNI T1w Template
  --t1Template2mm=<file path>       T1w MNI 2mm Template
  --t2Template=<file path>          MNI T2w template
  --t2TemplateBrain=<file path>     Brain extracted MNI T2w Template
  --t2Template2mm=<file path>       T2w MNI 2mm Template
  --templateMask=<file path>        Brain mask MNI Template
  --template2mmMask=<file path>     Brain mask MNI 2mm Template
  --brainSize=<size value>          Brain size estimate in mm, 150 for humans
  --linear=<yes/no>                 Do (not) use FNIRT for image registration to MNI
  [--custombrain=(NONE|MASK|CUSTOM)]  If you have created a custom brain mask saved as "<subject>/T1w/custom_acpc_mask.nii.gz", specify "MASK".
                                      If you have created custom structural images, e.g.:
                                      - "<subject>/T1w/T1w_acpc_brain_final.nii.gz"
                                      - "<subject>/T1w/T1w_acpc_final.nii.gz"
                                      - "<subject>/T1w/T2w_acpc_brain_final.nii.gz"
                                      - "<subject>/T1w/T2w_acpc_final.nii.gz"
                                      to be used when peforming MNI152 Atlas registration, specify "CUSTOM".
                                      When "MASK" or "CUSTOM" is specified, only the AtlasRegistration step is run.
                                      If the parameter is omitted or set to NONE (the default),
                                      standard image processing will take place.
                                      NOTE: This option allows manual correction of brain images in cases when they
                                      were not successfully processed and/or masked by the regular use of the pipelines.
                                      Before using this option, first ensure that the pipeline arguments used were
                                      correct and that templates are a good match to the data.
  --FNIRTConfig=<file path>         FNIRT 2mm T1w Configuration file

EOF
}

# Allow script to return a Usage statement, before any other output or checking
if [ "$#" = "0" ]; then
    show_usage
    exit 1
fi

# ------------------------------------------------------------------------------
#  Establish tool name for logging
# ------------------------------------------------------------------------------

log_SetToolName "${script_name}"

# ------------------------------------------------------------------------------
#  Parse Command Line Options
# ------------------------------------------------------------------------------

opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
	show_usage
    exit 0
fi

log_Msg "Platform Information Follows: "
uname -a

echo -e "\nParsing Command Line Opts"
studyName=`opts_GetOpt1 "--studyName" $@`
subject=`opts_GetOpt1 "--subject" $@`
b0=`opts_GetOpt1 "--b0" $@`
t1wInputImages=`opts_GetOpt1 "--t1" $@`
t2wInputImages=`opts_GetOpt1 "--t2" $@`
t1wTemplate=`opts_GetOpt1 "--t1Template" $@`
t1wTemplateBrain=`opts_GetOpt1 "--t1TemplateBrain" $@`
t1wTemplate2mm=`opts_GetOpt1 "--t1Template2mm" $@`
t2wTemplate=`opts_GetOpt1 "--t2Template" $@`
t2wTemplateBrain=`opts_GetOpt1 "--t2TemplateBrain" $@`
t2wTemplate2mm=`opts_GetOpt1 "--t2Template2mm" $@`
TemplateMask=`opts_GetOpt1 "--templateMask" $@`
Template2mmMask=`opts_GetOpt1 "--template2mmMask" $@`
brainSize=`opts_GetOpt1 "--brainSize" $@`
linear=`opts_GetOpt1 "--linear" $@`
windowSize=`opts_GetOpt1 "--windowSize" $@`
customBrain=`opts_GetOpt1 "--customBrain" $@`
FNIRTConfig=`opts_GetOpt1 "--FNIRTConfig" $@`
# Use --printcom=echo for just printing everything and not actually
# running the commands (the default is to actually run the commands)
RUN=`opts_GetOpt1 "--printcom" $@`

# ------------------------------------------------------------------------------
#  Show Command Line Options
# ------------------------------------------------------------------------------

log_Msg "studyName: ${studyName}"
log_Msg "subject: ${subject}"
log_Msg "b0: ${b0}"
log_Msg "t1wInputImages: ${t1wInputImages}"
log_Msg "t2wInputImages: ${t2wInputImages}"
log_Msg "t1wTemplate: ${t1wTemplate}"
log_Msg "t1wTemplateBrain: ${t1wTemplateBrain}"
log_Msg "t1wTemplate2mm: ${t1wTemplate2mm}"
log_Msg "t2wTemplate: ${t2wTemplate}"
log_Msg "t2wTemplateBrain: ${t2wTemplateBrain}"
log_Msg "t2wTemplate2mm: ${t2wTemplate2mm}"
log_Msg "TemplateMask: ${TemplateMask}"
log_Msg "Template2mmMask: ${Template2mmMask}"
log_Msg "brainSize: ${brainSize}"
log_Msg "linear: ${linear}"
log_Msg "windowSize: ${windowSize}"
log_Msg "customBrain: ${customBrain}"
log_Msg "FNIRTConfig: ${FNIRTConfig}"
log_Msg "Finished Parsing Command Line Options"

# ------------------------------------------------------------------------------
#  Show Environment Variables
# ------------------------------------------------------------------------------

echo -e "\nEnvironment Variables"
log_Msg "FSLDIR: ${FSLDIR}"
log_Msg "MATLABDIR: ${MATLABDIR}"
log_Msg "SPM12DIR: ${SPM12DIR}"
log_Msg "DBNDIR: ${DBNDIR}"
log_Msg "DBN Libraries: ${DBN_Libraries}"
log_Msg "RPPDIR: ${RPPDIR}"
log_Msg "RPP_Scripts: ${RPP_Scripts}"

# Naming Conventions
t1wImage="T1w"
t1wFolder="T1w" #Location of T1w images
t2wImage="T2w"
t2wFolder="T2w" #Location of T2w images

# ------------------------------------------------------------------------------
#  Build Paths and Unpack List of Images
# ------------------------------------------------------------------------------
t1wFolder=./tmp/${studyName}/preprocessed/RPP/${subject}/${b0}/${t1wFolder}
t2wFolder=./tmp/${studyName}/preprocessed/RPP/${subject}/${b0}/${t2wFolder}

log_Msg "t1wFolder: $t1wFolder"
log_Msg "t2wFolder: $t2wFolder"

# Unpack List of Images
t1wInputImages=`echo ${t1wInputImages} | sed 's/@/ /g'`
t2wInputImages=`echo ${t2wInputImages} | sed 's/@/ /g'`

# Are T2w images available?
if [ -z "${t2wInputImages}" ] ; then
    t2wFolder_t2wImageWithPath="NONE"
    t2wFolder_t2wImageWithPath_brain="NONE"
    t1wFolder_t2wImageWithPath_acpc="NONE"
else
    t2wFolder_t2wImageWithPath="${t2wFolder}/${t2wImage}_bc_fov"
    t2wFolder_t2wImageWithPath_brain="${t2wFolder}/${t2wImage}_bc_fov_brain"
    t2wFolder_t2wImageWithPath_brain_mask="${t2wFolder}/${t2wImage}_bc_fov_brain_mask"
    t1wFolder_t2wImageWithPath_acpc="${t1wFolder}/${t2wImage}_bc_fov_acpc"
fi

if [ ! -e ${t1wFolder}/xfms ] ; then
	log_Msg "mkdir -p ${t1wFolder}/xfms/"
	mkdir -p ${t1wFolder}/xfms/
fi

#if [ ! -e ${t2wFolder}/xfms ] && [ ${t2wFolder} != "NONE" ] ; then
if [[ ! -e ${t2wFolder}/xfms ]] && [[ -n ${t2wInputImages} ]] ; then
    log_Msg "mkdir -p ${t2wFolder}/xfms/"
    mkdir -p ${t2wFolder}/xfms/
fi

# ------------------------------------------------------------------------------
# We skip all the way to AtlasRegistration (last step) if using a custom brain
# mask or custom structural images ($customImage={MASK|CUSTOM})
# ------------------------------------------------------------------------------

if [ "$customBrain" = "NONE" ] ; then

# ------------------------------------------------------------------------------
#  Do primary work
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#  Loop over the processing for T1w and T2w (just with different names)
#  For each modality, perform
#  - Average same modality images (if more than one is available)
#  - Rigidly align images to specified MNI Template to create native volume space
#  - Perform Brain Extraction (FNIRT-based Masking)
# ------------------------------------------------------------------------------

    Modalities="T1w T2w"

    for tXw in ${Modalities} ; do
        # Set up appropriate input variables
        if [ $tXw = T1w ] ; then
            tXwInputImages="${t1wInputImages}"
            tXwFolder="${t1wFolder}"
            tXwImage="${t1wImage}"
            tXwTemplate="${t1wTemplate}"
            tXwTemplateBrain="${t1wTemplateBrain}"
            tXwTemplate2mm="${t1wTemplate2mm}"
        else
            tXwInputImages="${t2wInputImages}"
            tXwFolder="${t2wFolder}"
            tXwImage="${t2wImage}"
            tXwTemplate="${t2wTemplate}"
            tXwTemplateBrain="${t2wTemplateBrain}"
            tXwTemplate2mm="${t2wTemplate2mm}"
        fi
        outputTXwImageString=""

        # Skip modality if no image
        if [ -z "${tXwInputImages}" ] ; then
            echo ''
            log_Msg "Skipping Modality: $tXw - image not specified"
            echo ''
            continue
        else
            echo ''
            log_Msg "Processing Modality: $tXw"
        fi

        i=1
        for image in $tXwInputImages ; do
            # reorient image to mach the orientation of MNI152
            ${RUN} ${FSLDIR}/bin/fslreorient2std $image ${tXwFolder}/${tXwImage}${i}

            # ------------------------------------------------------------------------------
            # Bias Correction
            # ------------------------------------------------------------------------------
            # bc stands for bias corrected

            echo -e "\n...Performing Bias Correction"
            log_Msg "mkdir -p ${tXwFolder}/BiasCorrection"
            mkdir -p ${tXwFolder}/BiasCorrection
            ${RUN} ${RPP_Scripts}/BiasCorrection.sh \
                --workingDir=${tXwFolder}/BiasCorrection \
                --inputImage=${tXwFolder}/${tXwImage}${i} \
                --windowSize=${windowSize} \
                --outputImage=${tXwFolder}/${tXwImage}_bc${i}

            # always add the message/parameters specified
            outputTXwImageString="${outputTXwImageString}${tXwFolder}/${tXwImage}_bc${i}@"
            i=$(($i+1))
        done

        # ------------------------------------------------------------------------------
        # Average Like (Same Modality) Scans
        # ------------------------------------------------------------------------------

        echo -e "\n...Averaging ${tXw} Scans"
        if [ `echo $tXwInputImages | wc -w` -gt 1 ] ; then
            log_Msg "Averaging ${tXw} Images, performing simple averaging"
            log_Msg "mkdir -p ${tXwFolder}/Average${tXw}Images"
            mkdir -p ${tXwFolder}/Average${tXw}Images
            ${RUN} ${RPP_Scripts}/AnatomicalAverage.sh \
                --workingDir=${tXwFolder}/Average${tXw}Images \
                --imageList=${outputTXwImageString} \
                --ref=${tXwTemplate} \
                --refMask=${TemplateMask} \
                --brainSize=${brainSize} \
                --out=${tXwFolder}/${tXwImage}_bc \
                --crop=no \
                --clean=no \
                --verbose=yes
        else
            log_Msg "Only one image found, not averaging T1w images, just copying"
            ${RUN} ${FSLDIR}/bin/imcp ${tXwFolder}/${tXwImage}_bc1 ${tXwFolder}/${tXwImage}_bc
        fi

        # ------------------------------------------------------------------------------
        # Brain Extraction (FNIRT-based Masking)
        # ------------------------------------------------------------------------------

        echo -e "\n...Performing Brain Extraction using FNIRT-based Masking"
        log_Msg "mkdir -p ${tXwFolder}/BrainExtractionFNIRTbased"
        mkdir -p ${tXwFolder}/BrainExtractionFNIRTbased
        ${RUN} ${RPP_Scripts}/BrainExtractionFNIRTbased.sh \
            --workingDir=${tXwFolder}/BrainExtractionFNIRTbased \
            --in=${tXwFolder}/${tXwImage}_bc \
            --ref=${tXwTemplate} \
            --refMask=${TemplateMask} \
            --ref2mm=${tXwTemplate2mm} \
            --ref2mmMask=${Template2mmMask} \
            --outImage=${tXwFolder}/${tXwImage}_bc_fov \
            --outBrain=${tXwFolder}/${tXwImage}_bc_fov_brain \
            --outBrainMask=${tXwFolder}/${tXwImage}_bc_fov_brain_mask \
            --FNIRTConfig=${FNIRTConfig}



    done
    # End of looping over modalities (T1w and T2w)

    # ------------------------------------------------------------------------------
    # T2w to T1w Registration
    # ------------------------------------------------------------------------------


    echo -e "\n...Performing T2w to T1w Registration"
    if [ -z "${t2wInputImages}" ] ; then
        log_Msg "Skipping T2w to T1w registration --- no T2w image."

    else

        wdir=${t2wFolder}/t2wToT1wReg
        if [ -e ${wdir} ] ; then
            # DO NOT change the following line to "rm -r "{wdir}"" because the changes of
            # something going wrong with that are much higher, and rm -r always needs to
            # be treated with the utmost caution
            rm -r ${t2wFolder}/t2wToT1wReg
        fi

        log_Msg "mdir -p ${wdir}"
        mkdir -p ${wdir}

        ${RUN} ${RPP_Scripts}/T2wToT1wReg.sh \
            ${wdir} \
            ${t1wFolder}/${t1wImage}_bc_fov \
            ${t1wFolder}/${t1wImage}_bc_fov_brain \
            ${t2wFolder}/${t2wImage}_bc_fov \
            ${t2wFolder}/${t2wImage}_bc_fov_brain \
            ${t2wFolder}/${t2wImage}_bc_fov_brain_mask \
            ${t1wFolder}/${t1wImage}_bc_fov \
            ${t1wFolder}/${t1wImage}_bc_brain \
            ${t1wFolder}/xfms/${t1wImage} \
            ${t1wFolder}/${t2wImage}_bc_fov \
            ${t1wFolder}/${t2wImage}_bc_fov_brain \
            ${t1wFolder}/${t2wImage}_bc_fov_brain_mask \
            ${t1wFolder}/xfms/${t2wImage}_bc_reg
    fi

    # ------------------------------------------------------------------------------
    # ACPC align image to specified MNI Template to create native volume space
    # ------------------------------------------------------------------------------

    echo -e "\n...Aligning ${t1wImage} image to ${t1wTemplate} to create native volume space"
    log_Msg "mkdir -p ${t1wFolder}/ACPCAlignment"
    mkdir -p ${t1wFolder}/ACPCAlignment
    ${RUN} ${RPP_Scripts}/ACPCAlignment.sh \
        --workingDir=${t1wFolder}/ACPCAlignment \
        --inImage=${t1wFolder}/${t1wImage}_bc_fov \
        --inBrain=${t1wFolder}/${t1wImage}_bc_fov_brain \
        --inBrainMask=${t1wFolder}/${t1wImage}_bc_fov_brain_mask \
        --ref=${t1wTemplate} \
        --refBrain=${t1wTemplateBrain} \
        --full2roi=${t1wFolder}/BrainExtractionFNIRTbased/full2roi.mat \
        --roi2full=${t1wFolder}/BrainExtractionFNIRTbased/roi2full.mat \
        --outImage=${t1wFolder}/${t1wImage}_bc_fov_acpc \
        --outBrain=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain \
        --outBrainMask=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain_mask \
        --oMat=${t1wFolder}/xfms/acpc.mat \
        --brainSize=${brainSize}

    if [ -n "${t2wInputImages}" ] ; then

        # ------------------------------------------------------------------------------
        # ACPC align image to specified MNI Template to create native volume space
        # ------------------------------------------------------------------------------

        echo -e "\n...Aligning ${t2wImage} image to ${t2wTemplate} to create native volume space"
        log_Msg "mkdir -p ${t1wFolder}/ACPCAlignment"
        mkdir -p ${t2wFolder}/ACPCAlignment
        ${RUN} ${RPP_Scripts}/ACPCAlignment.sh \
            --workingDir=${t2wFolder}/ACPCAlignment \
            --inImage=${t1wFolder}/${t2wImage}_bc_fov \
            --inBrain=${t1wFolder}/${t2wImage}_bc_fov_brain \
            --inBrainMask=${t1wFolder}/${t2wImage}_bc_fov_brain_mask \
            --ref=${t1wTemplate} \
            --refBrain=${t1wTemplateBrain} \
            --full2roi=${t2wFolder}/BrainExtractionFNIRTbased/full2roi.mat \
            --roi2full=${t2wFolder}/BrainExtractionFNIRTbased/roi2full.mat \
            --outImage=${t2wFolder}/${t2wImage}_bc_fov_acpc \
            --outBrain=${t2wFolder}/${t2wImage}_bc_fov_acpc_brain \
            --outBrainMask=${t2wFolder}/${t2wImage}_bc_fov_acpc_brain_mask \
            --oMat=${t2wFolder}/xfms/acpc.mat \
            --brainSize=${brainSize}
    fi

    # ------------------------------------------------------------------------------
    # Create a One-Step Resampled Version of the T1w_acpc, T2w_acpc outputs
    # ------------------------------------------------------------------------------

    if [ -z "${t2wInputImages}" ] ; then

        echo -e "\n...Creating One-Step Resampled Version of the T1w_acpc Output"
        log_Msg "mkdir -p ${t1wFolder}/OneStepResampledACPC"
        mkdir -p ${t1wFolder}/OneStepResampledACPC
        ${RUN} ${RPP_Scripts}/OneStepResampledACPC.sh \
            --workingDir=${t1wFolder}/OneStepResampledACPC \
            --t1=${t1wFolder}/${t1wImage}_bc \
            --t1ACPC=${t1wFolder}/${t1wImage}_bc_fov_acpc \
            --t1ACPCBrain=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain \
            --t1w2ACPC=${t1wFolder}/xfms/acpc.mat \
            --T1w2T1w=${t1wFolder}/xfms/${t1wImage} \
            --ref=${t1wTemplate} \
            --oWarpT1=${t1wFolder}/xfms/origT1w2T1w \
            --oT1=${t1wFolder}/${t1wImage}_bc_fov_acpc \
            --oT1Brain=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain

    else

        echo -e "\n...Creating One-Step Resampled Version of the T1w_acpc, T2w_acpc outputs"
        log_Msg "mkdir -p ${t1wFolder}/OneStepResampledACPC"
        mkdir -p ${t1wFolder}/OneStepResampledACPC
        ${RUN} ${RPP_Scripts}/OneStepResampledACPC.sh \
            --workingDir=${t1wFolder}/OneStepResampledACPC \
            --t1=${t1wFolder}/${t1wImage}_bc \
            --t1ACPC=${t1wFolder}/${t1wImage}_bc_fov_acpc \
            --t1ACPCBrain=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain \
            --t1w2ACPC=${t1wFolder}/xfms/acpc.mat \
            --t1w2T1w=${t1wFolder}/xfms/${t1wImage} \
            --fullT1w2roi=${t1wFolder}/BrainExtractionFNIRTbased/full2roi.mat \
            --t2=${t2wFolder}/${t2wImage}_bc \
            --t2ACPC=${t2wFolder}/${t2wImage}_bc_fov_acpc \
            --t2ACPCBrain=${t2wFolder}/${t2wImage}_bc_fov_acpc_brain \
            --t2w2ACPC=${t2wFolder}/xfms/acpc.mat \
            --t2w2T1w=${t1wFolder}/xfms/${t2wImage}_bc_reg \
            --fullT2w2roi=${t2wFolder}/BrainExtractionFNIRTbased/full2roi.mat \
            --ref=${t1wTemplate} \
            --oWarpT1=${t1wFolder}/xfms/origT1w2T1w \
            --oT1=${t1wFolder}/${t1wImage}_bc_fov_acpc_final \
            --oT1Brain=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain_final \
            --oWarpT2=${t1wFolder}/xfms/origT2w2T1w \
            --oT2=${t1wFolder}/${t2wImage}_bc_fov_acpc_final \
            --oT2Brain=${t1wFolder}/${t2wImage}_bc_fov_acpc_brain_final

    fi

# ------------------------------------------------------------------------------
# Using custom mask
# ------------------------------------------------------------------------------
# The mask should be aligned with ACPC

elif [ "$customBrain" = "MASK" ] ; then

    echo -e "\n...Custom Mask provided, skipping all the steps to Atlas registration, applying custom mask."
    OutputT1wImage=${T1wFolder}/${T1wImage}_bc_acpc_final
    ${FSLDIR}/bin/fslmaths ${OutputT1wImage} -mas ${T1wFolder}/custom_bc_acpc_mask ${OutputT1wImage}_brain

    if [ -n "${t2wInputImages}" ] ; then

        OutputT2wImage=${T1wFolder}/${T2wImage}_bc_acpc_final
        ${FSLDIR}/bin/fslmaths ${OutputT2wImage} -mas ${T1wFolder}/custom_bc_acpc_mask ${OutputT2wImage}_brain
    fi


# ------------------------------------------------------------------------------
# Using custom structural images
# ------------------------------------------------------------------------------

else

    echo -e "\n...Custom structural images provided, skipping all the steps to Atlas registration, using existing images instead."

fi

# ------------------------------------------------------------------------------
#  Atlas Registration to MNI152
#  Also applies the MNI registration to T1w/T2w image
#  Performs either FLIRT or FLIRT + FNIRT depending on the value of linear
# ------------------------------------------------------------------------------

if [ $linear = yes ] ; then
    # ------------------------------------------------------------------------------
    #  Atlas Registration to MNI152: FLIRT
    # ------------------------------------------------------------------------------

    atlasSpaceFolder="MNILinear"
    atlasSpaceFolder=./tmp/${studyName}/preprocessed/RPP/${subject}/${b0}/${atlasSpaceFolder}

    log_Msg "atlasSpaceFolder: $atlasSpaceFolder"
    if [ ! -e ${atlasSpaceFolder}/xfms ] ; then
        log_Msg "mkdir -p ${atlasSpaceFolder}/xfms/"
        mkdir -p ${atlasSpaceFolder}/xfms/
    fi
    echo -e "\n...Performing Atlas Registration to MNI152 (FLIRT)"

    if [ -z "${t2wInputImages}" ] ; then

        ${RUN} ${RPP_Scripts}/AtlasRegistrationToMNI152FLIRT.sh \
            --workingDir=${atlasSpaceFolder} \
            --t1=${t1wFolder}/${t1wImage}_bc_acpc_final \
            --t1Brain=${t1wFolder}/${t1wImage}_bc_acpc_brain_final \
            --ref=${t1wTemplate} \
            --refBrain=${t1wTemplateBrain} \
            --refMask=${templateMask} \
            --oMat=${atlasSpaceFolder}/xfms/acpc2standard.nii.gz \
            --oInvMat=${atlasSpaceFolder}/xfms/standard2acpc.nii.gz \
            --oT1=${atlasSpaceFolder}/${t1wImage} \
            --oT1Brain=${atlasSpaceFolder}/${t1wImage}_brain

    else

        ${RUN} ${RPP_Scripts}/AtlasRegistrationToMNI152FLIRT.sh \
            --workingDir=${atlasSpaceFolder} \
            --t1=${t1wFolder}/${t1wImage}_bc_fov_acpc_final \
            --t1Brain=${t1wFolder}/${t1wImage}_bc_fov_acpc_brain_final \
            --t2=${t1wFolder}/${t2wImage}_bc_fov_acpc_final \
            --t2Brain=${t1wFolder}/${t2wImage}_bc_fov_acpc_brain_final \
            --ref=${t1wTemplate} \
            --refBrain=${t1wTemplateBrain} \
            --refMask=${TemplateMask} \
            --oMat=${atlasSpaceFolder}/xfms/acpc2standard.nii.gz \
            --oInvMat=${atlasSpaceFolder}/xfms/standard2acpc.nii.gz \
            --oT1=${atlasSpaceFolder}/${t1wImage} \
            --oT1Brain=${atlasSpaceFolder}/${t1wImage}_brain \
            --oT2=${atlasSpaceFolder}/${t2wImage} \
            --oT2Brain=${atlasSpaceFolder}/${t2wImage}_brain
    fi

    echo -e "\nLinear RPP Completed"

else

    # ------------------------------------------------------------------------------
    #  Atlas Registration to MNI152: FLIRT + FNIRT
    # ------------------------------------------------------------------------------

    atlasSpaceFolder="MNINonLinear"
    atlasSpaceFolder=./tmp/${studyName}/preprocessed/RPP/${subject}/${b0}/${atlasSpaceFolder}

    log_Msg "atlasSpaceFolder: $atlasSpaceFolder"
    if [ ! -e ${atlasSpaceFolder}/xfms ] ; then
        log_Msg "mkdir -p ${atlasSpaceFolder}/xfms/"
        mkdir -p ${atlasSpaceFolder}/xfms/
    fi

    echo -e "\n...Performing Atlas Registration to MNI152 (FLIRT and FNIRT)"

    if [ -z "${t2wInputImages}" ] ; then

        ${RUN} ${RPP_Scripts}/AtlasRegistrationToMNI152FLIRTandFNIRT.sh \
            --workingDir=${atlasSpaceFolder} \
            --t1=${t1wFolder}/${t1wImage}_bc_acpc_final \
            --t1Brain=${t1wFolder}/${t1wImage}_bc_acpc_brain_final \
            --ref=${t1wTemplate} \
            --refBrain=${t1wTemplateBrain} \
            --refMask=${TemplateMask} \
            --ref2mm=${t1wTemplate2mm} \
            --ref2mmMask=${template2mmMask} \
            --oWarp=${atlasSpaceFolder}/xfms/acpc2standard.nii.gz \
            --oInvWarp=${atlasSpaceFolder}/xfms/standard2acpc.nii.gz \
            --oT1=${atlasSpaceFolder}/${t1wImage} \
            --oT1Brain=${atlasSpaceFolder}/${t1wImage}_brain \
            --FNIRTConfig=${FNIRTConfig}

    else

        ${RUN} ${RPP_Scripts}/AtlasRegistrationToMNI152FLIRTandFNIRT.sh \
            --workingDir=${atlasSpaceFolder} \
            --t1=${t1wFolder}/${t1wImage}_bc_acpc_final \
            --t1Brain=${t1wFolder}/${t1wImage}_bc_acpc_brain_final \
            --t2=${t1wFolder}/${t2wImage}_bc_acpc_final \
            --t2Brain=${t1wFolder}/${t2wImage}_bc_acpc_brain_final \
            --ref=${t1wTemplate} \
            --refBrain=${t1wTemplateBrain} \
            --refMask=${TemplateMask} \
            --ref2mm=${t1wTemplate2mm} \
            --ref2mmMask=${Template2mmMask} \
            --oWarp=${atlasSpaceFolder}/xfms/acpc2standard.nii.gz \
            --oInvWarp=${atlasSpaceFolder}/xfms/standard2acpc.nii.gz \
            --oT1=${atlasSpaceFolder}/${t1wImage} \
            --oT1Brain=${atlasSpaceFolder}/${t1wImage}_brain \
            --oT2=${atlasSpaceFolder}/${t2wImage} \
            --oT2Brain=${atlasSpaceFolder}/${t2wImage}_brain \
            --FNIRTConfig=${FNIRTConfig}

    fi

    echo -e "\nNonlinear RPP Completed"
fi
