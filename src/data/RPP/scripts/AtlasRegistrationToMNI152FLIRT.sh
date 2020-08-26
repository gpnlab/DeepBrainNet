#!/bin/bash
set -e

# Requirements for this script
#  installed versions of: FSL (version 5.0.6)
#  environment: FSLDIR, DBN_Libraries, RPP_Config, MNI_Templates

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

if [ -z "${RPP_Config}" ]; then
	echo "$(basename ${0}): ABORTING: RPP_Config environment variable must be set"
	exit 1
#else
#	echo "$(basename ${0}): RPP_Config: ${RPP_Config}"
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
  echo "`basename $0`: Tool for linearly registering T1w to MNI space"
  echo " "
  echo "Usage: `basename $0` [--workingdir=<working dir>]"
  echo "                --t1=<t1w image>"
  echo "                --t1Brain=<brain extracted t1w image>"
  echo "                --ref=<reference image>"
  echo "                --refBrain=<reference brain image>"
  echo "                --refMask=<reference brain mask>"
  echo "                --oMat=<output warp>"
  echo "                --oInvMat=<output inverse warp>"
  echo "                --oT1=<output t1w to MNI>"
  echo "                --oT1Brain=<output, brain extracted t1w to MNI>"
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
Reference=`opts_GetOpt1 "--ref" $@`  # "$4"
ReferenceBrain=`opts_GetOpt1 "--refBrain" $@`  # "$5"
ReferenceMask=`opts_GetOpt1 "--refMask" $@`  # "$6
OutputTransform=`opts_GetOpt1 "--oMat" $@`  # "$9"
OutputInvTransform=`opts_GetOpt1 "--oInvMat" $@`  # "$10"
OutputT1wImage=`opts_GetOpt1 "--oT1" $@`  # "$11"
OutputT1wImageBrain=`opts_GetOpt1 "--oT1Brain" $@`  # "$12"
#FNIRTConfig=`opts_GetOpt1 "--FNIRTConfig" $@`  # "$13"

# default parameters
WD=`opts_DefaultOpt $WD .`
#Reference2mm=`opts_DefaultOpt $Reference2mm ${MNI_Templates}/MNI152_T1_2mm.nii.gz`
#Reference2mmMask=`opts_DefaultOpt $Reference2mmMask ${MNI_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz`
#FNIRTConfig=`opts_DefaultOpt $FNIRTConfig ${RPP_Config}/T1_2_MNI152_2mm.cnf`

#T1wBasename=`${FSLDIR}/bin/remove_ext $T1w`;
T1wBasename=`remove_ext $T1w`;
T1wBasename=`basename $T1wBasename`;
#T1wBrainBasename=`${FSLDIR}/bin/remove_ext $T1wBrain`;
T1wBrainBasename=`remove_ext $T1wBrain`;
T1wBrainBasename=`basename $T1wBrainBasename`;

log_Msg "START: Linear Atlas Registration to MNI152"

mkdir -p $WD

# Record the input options in a log file
echo "$0 $@" >> $WD/xfms/log.txt
echo "PWD = `pwd`" >> $WD/xfms/log.txt
echo "date: `date`" >> $WD/xfms/log.txt
echo " " >> $WD/xfms/log.txt

########################################## DO WORK ##########################################

# Linear then non-linear registration to MNI
${FSLDIR}/bin/flirt -interp spline -dof 12 -in ${T1wBrain} -ref ${ReferenceBrain} -omat ${OutputTransform} -out ${OutputT1wImageBrain}

# Invert affine transform
${FSLDIR}/bin/convert_xfm -omat ${OutputInvTransform} -inverse ${OutputTransform}

# T1w set of transformed outputs (brain/whole-head + restored/orig)
${FSLDIR}/bin/flirt -in ${T1w} -ref ${Reference} -out ${OutputT1wImage} -init ${OutputTransform} -applyxfm
${FSLDIR}/bin/flirt -in ${T1wBrain} -ref ${Reference} -out ${OutputT1wImageBrain} -init ${OutputTransform} -applyxfm
${FSLDIR}/bin/fslmaths ${OutputT1wImage} -mas ${OutputT1wImageBrain} ${OutputT1wImageBrain}

log_Msg "END: Linear AtlasRegistration to MNI152"
echo " END: `date`" >> $WD/xfms/log.txt

########################################## QA STUFF ##########################################

if [ -e $WD/xfms/qa.txt ] ; then rm -f $WD/xfms/qa.txt ; fi
echo "cd `pwd`" >> $WD/xfms/qa.txt
echo "# Check quality of alignment with MNI image" >> $WD/xfms/qa.txt
echo "fsleyes ${Reference} ${OutputT1wImage}" >> $WD/xfms/qa.txt

##############################################################################################
