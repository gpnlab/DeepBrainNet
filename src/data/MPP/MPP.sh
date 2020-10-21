#!/bin/bash
#
# # MPP.sh
#
# ## Description
#
# This script implements the Minimal Processng Pipeline (MPP) referred to in the
# README.md file
#
# The primary purposes of the MPP are:

# 1. To average any image repeats (i.e. multiple T1w or T2w images available)
# 2. To perform bias correction
# 2. To provide an initial robust brain extraction
# 4. To register the subject's structural images to the MNI space
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
# * MPPDIR
#
# * MPP_Scripts
#
#   Location of MPP sub-scripts that are used to carry out some of steps of the MPP.
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
# * The MNIFolder: ./tmp/${studyName}/${subject}/${b0}/MNI
#
# All outputs are generated in directories at or below these two main
# output directories.  The full list of output directories is:
#
# * ${t1wFolder}/AverageT1wImages
# * ${t1wFolder}/BrainExtractionRegistration(Segmentation)Based
# * ${t1wFolder}/xfms - transformation matrices and warp fields
#
# * ${t2wFolder}/AverageT1wImages
# * ${t2wFolder}/BrainExtractionRegistration(Segmentation)Based
# * ${t2wFolder}/xfms - transformation matrices and warp fields
#
# * ${MNIFolder}
# * ${MNIFolder}/xfms
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
# * MNIFolder Contents: TODO
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
. ${DBN_Libraries}/newopts.shlib # new Command line option functions

# ------------------------------------------------------------------------------
#  Show and Verify required environment variables are set
# ------------------------------------------------------------------------------

echo -e "\nEnvironment Variables"

log_Check_Env_Var DBNDIR
log_Check_Env_Var DBN_Libraries
log_Check_Env_Var MPPDIR
log_Check_Env_Var MPP_Scripts
log_Check_Env_Var FSLDIR
#change laptop
log_Check_Env_Var MATLABDIR
log_Check_Env_Var SPM12DIR

# ------------------------------------------------------------------------------
#  Usage Description Function
# ------------------------------------------------------------------------------
function usage()
{
    echo "
    $log_ToolName: Perform Minimal Processing Pipeline (MPP)

Usage: $log_ToolName
                    --studyName=<studyName>           Name of study
                                                      Used with --subject input to create path to
                                                      directory for all outputs generated as
                                                      ./tmp/studyName/subject
                    --subject=<subject>               Subject ID
                                                      Used with --studyName input to create path to
                                                      directory for all outputs generated as
                                                      ./tmp/studyName/subject
                    [--b0=<b0>=<3T|7T>]               Magniture of the B0 field
                    --t1=<T1w images>                 An @ symbol separated list of full paths to
                                                      T1-weighted (T1w) structural images for
                                                      the subject
                    [--t2=<T2w images>]               An @ symbol separated list of full paths to
                                                      T2-weighted (T2w) structural images for
                                                      the subject
                    --t1Template=<file path>          MNI T1w template
                    --t1TemplateBrain=<file path>     Brain extracted MNI T1w Template
                    --t1Template2mm=<file path>       T1w MNI 2mm Template
                    [--t2Template=<file path>]        MNI T2w template
                    [--t2TemplateBrain=<file path>]   Brain extracted MNI T2w Template
                    [--t2Template2mm=<file path>]     T2w MNI 2mm Template
                    --templateMask=<file path>        Brain mask MNI Template
                    --template2mmMask=<file path>     Brain mask MNI 2mm Template
                    [--custombrain=<NONE|MASK|CUSTOM>] If you have created a custom brain mask saved as
                                                       '<subject>/T1w/custom_bc_brain_mask.nii.gz', specify 'MASK'.
                                                       If you have created custom structural images, e.g.:
                                                       - '<subject>/T1w/T1w_bc.nii.gz'
                                                       - '<subject>/T1w/T1w_bc_brain.nii.gz'
                                                       - '<subject>/T1w/T2w_bc.nii.gz'
                                                       - '<subject>/T1w/T2w_bc_brain.nii.gz'
                                                       to be used when peforming MNI152 Atlas registration, specify
                                                       'CUSTOM'. When 'MASK' or 'CUSTOM' is specified, only the
                                                        AtlasRegistration step is run.
                                                        If the parameter is omitted or set to NONE (the default),
                                                        standard image processing will take place.
                                                        NOTE: This option allows manual correction of brain images
                                                        in cases when they were not successfully processed and/or
                                                        masked by the regular use of the pipelines.
                                                        Before using this option, first ensure that the pipeline
                                                        arguments used were correct and that templates are a good
                                                        match to the data.
                    [--brainSize=<int>]                Brain size estimate in mm, default 150 for humans
                    [--windowSize=<int>]               window size for bias correction, default 30.
                    [--brainExtractionMethod=<RPP|SPP>] Registration (Segmentation) based brain extraction
                    [--MNIRegistrationMethod=<nonlinear|linear>] Do (not) use FNIRT for image registration to MNI
                    [--printcom=command]              if 'echo' specified, will only perform a dry run.
                    [--FNIRTConfig=<file path>]       FNIRT 2mm T1w Configuration file

                    PARAMETERs are [ ] = optional; < > = user supplied value

                    Values default to running the example with sample data
"
    opts_ShowArguments
}

input_parser() {
    opts_AddMandatory '--studyName' 'studyName' 'Study Name' "a required value; the study name"
    opts_AddMandatory '--subject' 'subject' 'Subject ID' "a required value; the subject ID"
    opts_AddOptional '--b0' 'b0' 'Magnetic Field Strength' "an optinal value; the magnetic field strength. Default: 3T. Supported: 3T|7T." "3T"
    opts_AddMandatory '--t1' 't1wInputImages' 'T1w Input Images' "a required value; a string with the paths to the subjects T1w images delimited by the symbol @"
    opts_AddOptional '--t2' 't2wInputImages' 'T2w Input Images' "an optional value; a string with the paths to the subjects T2w images delimited by the symbol @. Default: NONE" "NONE"
    opts_AddMandatory '--t1Template' 't1wTemplate' 'MNI T1w Template' "a required value; the MNI T1w image reference template"
    opts_AddMandatory '--t1TemplateBrain' 't1wTemplateBrain' 'MNI T1w Brain Template' "a required value; the MNI T1w lmage brain extracted reference template"
    opts_AddMandatory '--t1Template2mm' 't1wTemplate2mm' 'MNI T1w 2mm Template' "a required value; the low-resolution 2mm MNI T1w image reference template"
#TODO: change t2Template to be truly optional
    opts_AddMandatory '--t2Template' 't2wTemplate' 'MNI T2w Template' "an optional value; the MNI T2w image reference template"
#TODO: change t2TemplateBrain to be truly optional
    opts_AddMandatory '--t2TemplateBrain' 't2wTemplateBrain' 'MNI T2w Brain Template' "a required value; the MNI T2w lmage brain extracted reference template"
#TODO: change t2Template2mm to be truly optional
    opts_AddMandatory '--t2Template2mm' 't2wTemplate2mm' 'MNI T2w 2mm Template' "a required value; the low-resolution 2mm MNI T2w image reference template"
    opts_AddMandatory '--templateMask' 'TemplateMask' 'Template Mask' "a required value; the MNI Template Brain Mask"
    opts_AddMandatory '--template2mmMask' 'Template2mmMask' 'Template 2mm Mask' "a required value; the MNI 2mm Template Brain Mask"
    opts_AddOptional '--customBrain' 'customBrain' 'Switch to select pipeline steps' "an optional value; a switch determining which steps of the pipeline need to be performed. If NONE, perform all steps, if MASK, skip brain extraction, if CUSTOM, performs only MNI Registration. Default: NONE. Supported: NONE|MASK|CUSTOM" "NONE"
    opts_AddOptional '--brainSize' 'brainSize' 'Brain Size' "an optional value; the average brain size in mm. Default: 150." "150"
    opts_AddOptional '--windowSize' 'windowSize' 'Window Size for Bias Correction' "an optional value; the window size for bias correction. Default: 30" "30"
    opts_AddOptional '--brainExtractionMethod' 'brainExtractionMethod' 'Brain Registration Method' "an optional value; the method used to perform brain extraction. Default: RPP. Supported: RPP|SPP" "RPP"
    opts_AddOptional '--MNIRegistrationMethod' 'MNIRegistrationMethod' 'MNI Registration Method' "an optional value; the method used to perform registration to MNI space. Default: linear. Supported: linear|nonlinear" "linear"
#TODO: change FNIRTConfig to be truly optional
    opts_AddOptional '--printcom' 'RUN' 'Run command' "an optional value; if the scripts invoked by this script will run or be just printed. Default: ''. Supported: ''|echo" ""
    opts_AddMandatory '--FNIRTConfig' 'FNIRTConfig' 'FNIRT Configuration' "an optional value, only required if MNI Registration method is nonlinear; the FNIRT FSL configuration file"

    opts_ParseArguments "$@"

}

# ------------------------------------------------------------------------------
#  Parse Command Line Options
# ------------------------------------------------------------------------------

log_Msg "Platform Information Follows: "
uname -a

echo -e "\nParsing Command Line Opts"
input_parser "$@"

# ------------------------------------------------------------------------------
#  Show Command Line Options
# ------------------------------------------------------------------------------
opts_ShowValues

# Naming Conventions
t1wImage="T1w"
t1wFolder="T1w" #Location of T1w images
t2wImage="T2w"
t2wFolder="T2w" #Location of T2w images
MNIFolder="MNI"

# ------------------------------------------------------------------------------
#  Build Paths and Unpack List of Images
# ------------------------------------------------------------------------------
t1wFolder=./${studyName}/preprocessed/${brainExtractionMethod}/${MNIRegistrationMethod}/${subject}/${b0}/${t1wFolder}
t2wFolder=./${studyName}/preprocessed/${brainExtractionMethod}/${MNIRegistrationMethod}/${subject}/${b0}/${t2wFolder}
MNIFolder=./${studyName}/preprocessed/${brainExtractionMethod}/${MNIRegistrationMethod}/${subject}/${b0}/${MNIFolder}

log_Msg "t1wFolder: $t1wFolder"
log_Msg "t2wFolder: $t2wFolder"

# Unpack List of Images
t1wInputImages=`echo ${t1wInputImages} | sed 's/@/ /g'`
t2wInputImages=`echo ${t2wInputImages} | sed 's/@/ /g'`

if [ ! -e ${t1wFolder}/xfms ] ; then
	log_Msg "mkdir -p ${t1wFolder}/xfms/"
	mkdir -p ${t1wFolder}/xfms/
fi

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
#  - Perform Brain Extraction (FNIRT-based or Segmentation-based Masking)
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
            ${RUN} ${MPP_Scripts}/BiasCorrection.sh \
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
            ${RUN} ${MPP_Scripts}/AnatomicalAverage.sh \
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

        if [ "$brainExtractionMethod" = "RPP" ] ; then

            # ------------------------------------------------------------------------------
            # Brain Extraction (FNIRT-based Masking)
            # ------------------------------------------------------------------------------

            echo -e "\n...Performing Brain Extraction using FNIRT-based Masking"
            log_Msg "mkdir -p ${tXwFolder}/BrainExtractionRegistrationBased"
            mkdir -p ${tXwFolder}/BrainExtractionRegistrationBased
            ${RUN} ${MPP_Scripts}/BrainExtractionRegistrationBased.sh \
                --workingDir=${tXwFolder}/BrainExtractionRegistrationBased \
                --in=${tXwFolder}/${tXwImage}_bc \
                --ref=${tXwTemplate} \
                --refMask=${TemplateMask} \
                --ref2mm=${tXwTemplate2mm} \
                --ref2mmMask=${Template2mmMask} \
                --outImage=${tXwFolder}/${tXwImage}_bc \
                --outBrain=${tXwFolder}/${tXwImage}_bc_brain \
                --outBrainMask=${tXwFolder}/${tXwImage}_bc_brain_mask \
                --FNIRTConfig=${FNIRTConfig}

        else

            # ------------------------------------------------------------------------------
            # Brain Extraction (Segmentation-based Masking)
            # ------------------------------------------------------------------------------

            echo -e "\n...Performing Brain Extraction using Segmentation-based Masking"
            log_Msg "mkdir -p ${tXwFolder}/BrainExtractionSegmentationBased"
            mkdir -p ${tXwFolder}/BrainExtractionSegmentationBased
            ${RUN} ${MPP_Scripts}/BrainExtractionSegmentationBased.sh \
                --workingDir=${tXwFolder}/BrainExtractionSegmentationBased \
                --segmentationDir=${t2wFolder}/BiasCorrection \
                --in=${tXwFolder}/${tXwImage}_bc \
                --outImage=${tXwFolder}/${tXwImage}_bc \
                --outBrain=${tXwFolder}/${tXwImage}_bc_brain \
                --outBrainMask=${tXwFolder}/${tXwImage}_bc_brain_mask
        fi

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

        ${RUN} ${MPP_Scripts}/T2wToT1wReg.sh \
            ${wdir} \
            ${t1wFolder}/${t1wImage}_bc \
            ${t1wFolder}/${t1wImage}_bc_brain \
            ${t2wFolder}/${t2wImage}_bc \
            ${t2wFolder}/${t2wImage}_bc_brain \
            ${t2wFolder}/${t2wImage}_bc_brain_mask \
            ${t1wFolder}/${t1wImage}_bc \
            ${t1wFolder}/${t1wImage}_bc_brain \
            ${t1wFolder}/xfms/${t1wImage} \
            ${t1wFolder}/${t2wImage}_bc \
            ${t1wFolder}/${t2wImage}_bc_brain \
            ${t1wFolder}/${t2wImage}_bc_brain_mask \
            ${t1wFolder}/xfms/${t2wImage}_bc_reg
    fi

# ------------------------------------------------------------------------------
# Using custom mask
# ------------------------------------------------------------------------------

elif [ "$customBrain" = "MASK" ] ; then

    echo -e "\n...Custom Mask provided, skipping all the steps to Atlas registration, applying custom mask."
    OutputT1wImage=${T1wFolder}/${T1wImage}_bc
    ${FSLDIR}/bin/fslmaths ${OutputT1wImage} -mas ${T1wFolder}/${t1wImage}_bc_brain_mask ${OutputT1wImage}_brain

    if [ -n "${t2wInputImages}" ] ; then

        OutputT2wImage=${T1wFolder}/${T2wImage}_bc
        ${FSLDIR}/bin/fslmaths ${OutputT2wImage} -mas ${T1wFolder}/${t2wImage}_bc_brain_mask ${OutputT2wImage}_brain
    fi


# Using custom structural images
# ------------------------------------------------------------------------------

else

    echo -e "\n...Custom structural images provided, skipping all the steps to Atlas registration, using existing images instead."

fi

# ------------------------------------------------------------------------------
#  Registration to MNI152
#  Performs either FLIRT or FLIRT + FNIRT depending on the value of MNIRegistrationMethod
# ------------------------------------------------------------------------------

log_Msg "MNIFolder: $MNIFolder"
if [ ! -e ${MNIFolder}/xfms ] ; then
    log_Msg "mkdir -p ${MNIFolder}/xfms/"
    mkdir -p ${MNIFolder}/xfms/
fi

if [ $MNIRegistrationMethod = linear ] ; then

    # ------------------------------------------------------------------------------
    #  Linear Registration to MNI152: FLIRT
    # ------------------------------------------------------------------------------

    echo -e "\n...Performing Linear Atlas Registration to MNI152 (FLIRT)"
    registrationScript=AtlasRegistrationToMNI152FLIRT.sh

else

    # ------------------------------------------------------------------------------
    #  Nonlinear Registration to MNI152: FLIRT + FNIRT
    # ------------------------------------------------------------------------------

    echo -e "\n...Performing Nonlinear Registration to MNI152 (FLIRT and FNIRT)"
    registrationScript=AtlasRegistrationToMNI152FLIRTandFNIRT.sh
fi


if [ -z "${t2wInputImages}" ] ; then

    ${RUN} ${MPP_Scripts}/${registrationScript} \
        --workingDir=${MNIFolder} \
        --t1=${t1wFolder}/${t1wImage}_bc \
        --t1Brain=${t1wFolder}/${t1wImage}_bc_brain \
        --t1BrainMask=${t1wFolder}/${t1wImage}_bc_brain_mask \
        --ref=${t1wTemplate} \
        --refBrain=${t1wTemplateBrain} \
        --refMask=${TemplateMask} \
        --oWarp=${MNIFolder}/xfms/acpc2standard.nii.gz \
        --oInvWarp=${MNIFolder}/xfms/standard2acpc.nii.gz \
        --oT1=${MNIFolder}/${t1wImage} \
        --oT1Brain=${MNIFolder}/${t1wImage}_brain \
        --oT1BrainMask=${MNIFolder}/${t1wImage}_brain_mask

else

    ${RUN} ${MPP_Scripts}/${registrationScript} \
        --workingDir=${MNIFolder} \
        --t1=${t1wFolder}/${t1wImage}_bc \
        --t1Brain=${t1wFolder}/${t1wImage}_bc_brain \
        --t1BrainMask=${t1wFolder}/${t1wImage}_bc_brain_mask \
        --t2=${t1wFolder}/${t2wImage}_bc \
        --t2Brain=${t1wFolder}/${t2wImage}_bc_brain \
        --t2BrainMask=${t1wFolder}/${t2wImage}_bc_brain_mask \
        --ref=${t1wTemplate} \
        --refBrain=${t1wTemplateBrain} \
        --refMask=${TemplateMask} \
        --oWarp=${MNIFolder}/xfms/acpc2standard.nii.gz \
        --oInvWarp=${MNIFolder}/xfms/standard2acpc.nii.gz \
        --oT1=${MNIFolder}/${t1wImage} \
        --oT1Brain=${MNIFolder}/${t1wImage}_brain \
        --oT1BrainMask=${MNIFolder}/${t1wImage}_brain_mask \
        --oT2=${MNIFolder}/${t2wImage} \
        --oT2Brain=${MNIFolder}/${t2wImage}_brain \
        --oT2BrainMask=${MNIFolder}/${t2wImage}_brain_mask
fi

# ------------------------------------------------------------------------------
#  Processing Pipeline Completed!
# ------------------------------------------------------------------------------
echo -e "\n${brainExtractionMethod} ${MNIRegistrationMethod} completed!"
