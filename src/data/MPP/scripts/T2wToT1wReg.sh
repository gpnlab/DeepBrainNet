#!/bin/bash 

# Requirements for this script
#  installed versions of: FSL
#  environment: HCPPIPEDIR, FSLDIR

# ------------------------------------------------------------------------------
#  Usage Description Function
# ------------------------------------------------------------------------------

script_name=$(basename "${0}")

Usage() {
	cat <<EOF

${script_name}: Script for registering T2w to T1w

Usage: ${script_name}

Usage information To Be Written

EOF
}

# Allow script to return a Usage statement, before any other output or checking
if [ "$#" = "0" ]; then
    Usage
    exit 1
fi


#################################### SUPPORT FUNCTIONS #####################################
if [ -z "${DBN_Libraries}" ]; then
	echo "$(basename ${0}): ABORTING: DBN_Libraries environment variable must be set"
	exit 1
fi

. ${DBN_Libraries}/log.shlib # Logging related functions
. ${DBN_Libraries}/opts.shlib # command line option functions

# ------------------------------------------------------------------------------
#  Verify required environment variables are set and log value
# ------------------------------------------------------------------------------

log_Check_Env_Var FSLDIR

########################################## DO WORK ##########################################


log_Msg "START: T2w2T1Reg"

WD="$1"
T1wImage="$2"
T1wImageBrain="$3"
T2wImage="$4"
T2wBrain="$5"
T2wBrainMask="$6"
OutputT1wImage="$7"
OutputT1wImageBrain="$8"
OutputT1wTransform="$9"
OutputT2wImage="${10}"
OutputT2wBrain="${11}"
OutputT2wBrainMask="${12}"
OutputT2wTransform="${13}"

T1wImageBrainFile=`basename "$T1wImageBrain"`

${FSLDIR}/bin/imcp "$T1wImageBrain" "$WD"/"$T1wImageBrainFile"

${FSLDIR}/bin/epi_reg --epi="$T2wBrain" --t1="$T1wImage" --t1brain="$WD"/"$T1wImageBrainFile" --out="$WD"/T2w2T1w
${FSLDIR}/bin/applywarp --rel --interp=spline --in="$T2wImage" --ref="$T1wImage" --premat="$WD"/T2w2T1w.mat --out="$WD"/T2w2T1w
${FSLDIR}/bin/fslmaths "$WD"/T2w2T1w -add 1 "$WD"/T2w2T1w -odt float

${FSLDIR}/bin/applywarp --rel --interp=spline --in="$T2wBrain" --ref="$T1wImage" --premat="$WD"/T2w2T1w.mat --out="$WD"/T2w2T1wBrain
#${FSLDIR}/bin/fslmaths "$WD"/T2w2T1wBrain -add 1 "$WD"/T2w2T1wBrain -odt float

${FSLDIR}/bin/applywarp --rel --interp=nn -i "$T2wBrainMask" -r "$T1wImage" --premat="$WD"/T2w2T1w.mat -o "$OutputT2wBrainMask"

${FSLDIR}/bin/imcp "$T1wImage" "$OutputT1wImage"

#${FSLDIR}/bin/imcp "$T1wImageBrain" "$OutputT1wImageBrain"
${FSLDIR}/bin/fslmaths "$OutputT1wImage" -mas "$OutputT2wBrainMask" "$OutputT1wImageBrain"
${FSLDIR}/bin/fslmaths "$OutputT1wImageBrain" -abs "$OutputT1wImageBrain" -odt float

${FSLDIR}/bin/fslmerge -t $OutputT1wTransform "$T1wImage".nii.gz "$T1wImage".nii.gz "$T1wImage".nii.gz
${FSLDIR}/bin/fslmaths $OutputT1wTransform -mul 0 $OutputT1wTransform

${FSLDIR}/bin/imcp "$WD"/T2w2T1w "$OutputT2wImage"
${FSLDIR}/bin/fslmaths "$OutputT2Image" -abs "$OutputT2wImage" -odt float
${FSLDIR}/bin/imcp "$WD"/T2w2T1wBrain "$OutputT2wBrain"
${FSLDIR}/bin/fslmaths "$OutputT2Brain" -abs "$OutputT2wBrain" -odt float

# OutputT2wImage is actually in T1w space (is the co-registered T1); This warp does nothing to the input, it's an identity warp. So the final transformation is equivalent to postmat.
${FSLDIR}/bin/convertwarp --relout --rel -r "$OutputT2wImage".nii.gz -w $OutputT1wTransform --postmat="$WD"/T2w2T1w.mat --out="$OutputT2wTransform"

log_Msg "END: T2w2T1Reg"
