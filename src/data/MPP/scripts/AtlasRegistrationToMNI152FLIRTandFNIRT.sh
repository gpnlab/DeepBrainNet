#!/bin/bash
set -e

# Requirements for this script
#  installed versions of: FSL (version 5.0.6)
#  environment: FSLDIR, DBN_Libraries, MPP_Config, MNI_Templates

# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------

if [ -z "${DBN_Libraries}" ]; then
	echo "$(basename ${0}): ABORTING: DBN_Libraries environment variable must be set"
	exit 1
#else
#	echo "$(basename ${0}): DBN_Libraries: ${DBN_Libraries}"
fi

if [ -z "${MNI_Templates}" ]; then
	echo "$(basename ${0}): ABORTING: MNI_Templates environment variable must be set"
	exit 1
#else
#	echo "$(basename ${0}): MNI_Templates: ${MNI_Templates}"
fi

if [ -z "${MPP_Config}" ]; then
	echo "$(basename ${0}): ABORTING: MPP_Config environment variable must be set"
	exit 1
#else
#	echo "$(basename ${0}): MPP_Config: ${MPP_Config}"
fi

if [ -z "${FSLDIR}" ]; then
	echo "$(basename ${0}): ABORTING: FSLDIR environment variable must be set"
	exit 1
#else
#	echo "$(basename ${0}): FSLDIR: ${FSLDIR}"
fi

################################################ SUPPORT FUNCTIONS ##################################################

. ${DBN_Libraries}/log.shlib # Logging related functions
. ${DBN_Libraries}/opts.shlib # command line option functions

Usage() {
  echo "`basename $0`: Tool for non-linearly registering T1w to MNI space"
  echo " "
  echo "Usage: `basename $0` [--workingdir=<working dir>]"
  echo "                --t1=<t1w image>"
  echo "                --t1Brain=<brain extracted t1w image>"
  echo "                --ref=<reference image>"
  echo "                --refBrain=<reference brain image>"
  echo "                --refMask=<reference brain mask>"
  echo "                [--ref2mm=<reference 2mm image>]"
  echo "                [--ref2mmMask=<reference 2mm brain mask>]"
  echo "                --oWarp=<output warp>"
  echo "                --oInvWarp=<output inverse warp>"
  echo "                --oT1=<output t1w to MNI>"
  echo "                --oT1Brain=<output, brain extracted t1w to MNI>"
  echo "                [--FNIRTConfig=<FNIRT configuration file>]"
}

###################################### OUTPUT FILES #############################################

# Outputs (in $WD):  xfms/acpc2MNILinear.mat
#                    xfms/${T1wBrainBasename}_to_MNILinear
#                    xfms/IntensityModulatedT1.nii.gz  xfms/NonlinearRegJacobians.nii.gz
#                    xfms/IntensityModulatedT1.nii.gz  xfms/2mmReg.nii.gz
#                    xfms/NonlinearReg.txt  xfms/NonlinearIntensities.nii.gz
#                    xfms/NonlinearReg.nii.gz
# Outputs (not in $WD): ${OutputTransform} ${OutputInvTransform}
#                       ${OutputT1wImage} ${OutputT1wImage}
#                       ${OutputT1wImageBrain}
###################################### OPTION PARSING ###########################################

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
# check for correct options
if [ $# -lt 9 ] ; then Usage; exit 1; fi

# parse arguments
WD=`opts_GetOpt1 "--workingDir" $@`  # "$1"
T1w=`opts_GetOpt1 "--t1" $@`  # "$2"
T1wBrain=`opts_GetOpt1 "--t1Brain" $@`  # "$3"
T1wBrainMask=`opts_GetOpt1 "--t1BrainMask" $@`  # "$3"
T2w=`opts_GetOpt1 "--t2" $@`  # "$2"
T2wBrain=`opts_GetOpt1 "--t2Brain" $@`  # "$3"
T2wBrainMask=`opts_GetOpt1 "--t2BrainMask" $@`  # "$3"
Reference=`opts_GetOpt1 "--ref" $@`  # "$4"
ReferenceBrain=`opts_GetOpt1 "--refBrain" $@`  # "$5"
ReferenceMask=`opts_GetOpt1 "--refMask" $@`  # "$6"
Reference2mm=`opts_GetOpt1 "--ref2mm" $@`  # "$7"
Reference2mmMask=`opts_GetOpt1 "--ref2mmMask" $@`  # "$8"
OutputTransform=`opts_GetOpt1 "--oWarp" $@`  # "$9"
OutputInvTransform=`opts_GetOpt1 "--oInvWarp" $@`  # "$10"
OutputT1wImage=`opts_GetOpt1 "--oT1" $@`  # "$11"
OutputT1wImageBrain=`opts_GetOpt1 "--oT1Brain" $@`  # "$12"
OutputT1wImageBrainMask=`opts_GetOpt1 "--oT1BrainMask" $@`  # "$12"
OutputT2wImage=`opts_GetOpt1 "--oT2" $@`  # "$11"
OutputT2wImageBrain=`opts_GetOpt1 "--oT2Brain" $@`  # "$12"
OutputT2wImageBrainMask=`opts_GetOpt1 "--oT2BrainMask" $@`  # "$12"
FNIRTConfig=`opts_GetOpt1 "--FNIRTConfig" $@`  # "$13"

# default parameters
WD=`opts_DefaultOpt $WD .`
Reference2mm=`opts_DefaultOpt $Reference2mm ${MNI_Templates}/MNI152_T1_2mm.nii.gz`
Reference2mmMask=`opts_DefaultOpt $Reference2mmMask ${MNI_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz`
FNIRTConfig=`opts_DefaultOpt $FNIRTConfig ${MPP_Config}/T1_2_MNI152_2mm.cnf`

#T1wBasename=`${FSLDIR}/bin/remove_ext $T1w`;
T1wBasename=`remove_ext $T1w`;
T1wBasename=`basename $T1wBasename`;
#T1wBrainBasename=`${FSLDIR}/bin/remove_ext $T1wBrain`;
T1wBrainBasename=`remove_ext $T1wBrain`;
T1wBrainBasename=`basename $T1wBrainBasename`;

log_Msg "START: Nonlinear Atlas Registration to MNI152"

mkdir -p $WD

# Record the input options in a log file
echo "$0 $@" >> $WD/xfms/log.txt
echo "PWD = `pwd`" >> $WD/xfms/log.txt
echo "date: `date`" >> $WD/xfms/log.txt
echo " " >> $WD/xfms/log.txt

# ------------------------------------------------------------------------------
# DO WORK
# ------------------------------------------------------------------------------

# Linear then non-linear registration to MNI
${FSLDIR}/bin/flirt -interp spline -dof 12 -in ${T1wBrain} -ref ${ReferenceBrain} -omat ${WD}/xfms/acpc2MNILinear.mat -out ${WD}/xfms/${T1wBrainBasename}_to_MNILinear

${FSLDIR}/bin/fnirt --in=${T1w} --ref=${Reference2mm} --aff=${WD}/xfms/acpc2MNILinear.mat --refmask=${Reference2mmMask} --fout=${OutputTransform} --jout=${WD}/xfms/NonlinearRegJacobians.nii.gz --refout=${WD}/xfms/IntensityModulatedT1.nii.gz --iout=${WD}/xfms/2mmReg.nii.gz --logout=${WD}/xfms/NonlinearReg.txt --intout=${WD}/xfms/NonlinearIntensities.nii.gz --cout=${WD}/xfms/NonlinearReg.nii.gz --config=${FNIRTConfig}

# Input and reference spaces are the same, using 2mm reference to save time
${FSLDIR}/bin/invwarp -w ${OutputTransform} -o ${OutputInvTransform} -r ${Reference2mm}

# T1w set of warped outputs (brain/whole-head + orig)
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${T1w} -r ${Reference} -w ${OutputTransform} -o ${OutputT1wImage}
${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T1wBrain} -r ${Reference} -w ${OutputTransform} -o ${OutputT1wImageBrain}
${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T1wBrainMask} -r ${Reference} -w ${OutputTransform} -o ${OutputT1wImageBrainMask}

${FSLDIR}/bin/fslmaths ${OutputT1wImageBrain} -abs ${OutputT1wImageBrain} -odt float
${FSLDIR}/bin/fslmaths ${OutputT1wImageBrainMask} -abs ${OutputT1wImageBrainMask} -odt float

${FSLDIR}/bin/fslmaths ${OutputT1wImage} -mas ${OutputT1wImageBrain} ${OutputT1wImageBrain}


# T2w set of warped outputs(brain/whole-head + orig)
if [ -n "${T2w}" ] ; then

    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${T2w} -r ${Reference} -w ${OutputTransform} -o ${OutputT2wImage}
    ${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T2wBrain} -r ${Reference} -w ${OutputTransform} -o ${OutputT2wImageBrain}
    ${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T2wBrainMask} -r ${Reference} -w ${OutputTransform} -o ${OutputT2wImageBrainMask}

    ${FSLDIR}/bin/fslmaths ${OutputT2wImageBrain} -abs ${OutputT2wImageBrain} -odt float
    ${FSLDIR}/bin/fslmaths ${OutputT2wImageBrainMask} -abs ${OutputT2wImageBrainMask} -odt float

    ${FSLDIR}/bin/fslmaths ${OutputT2wImage} -mas ${OutputT2wImageBrain} ${OutputT2wImageBrain}

fi


log_Msg "END: Nonlinear AtlasRegistration to MNI152"
echo " END: `date`" >> $WD/xfms/log.txt

# ------------------------------------------------------------------------------
# QA STUFF
# ------------------------------------------------------------------------------

if [ -e $WD/xfms/qa.txt ] ; then rm -f $WD/xfms/qa.txt ; fi
echo "cd `pwd`" >> $WD/xfms/qa.txt
echo "# Check quality of alignment with MNI image" >> $WD/xfms/qa.txt
echo "fsleyes ${Reference} ${OutputT1wImage}" >> $WD/xfms/qa.txt
echo "fsleyes ${Reference} ${OutputT2wImage}" >> $WD/xfms/qa.txt
