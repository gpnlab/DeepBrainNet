#!/bin/bash

#SBATCH --error=./logs/slurm/slurm-%A_%a.err
#SBATCH --output=./logs/slurm/slurm-%A_%a.out

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
# The hostname from which sbatch was invoked (e.g. obelix)
SERVER=$SLURM_SUBMIT_HOST
# The name of the nome running the job script (e.g. cluster)
NODE=$SLURMD_NODENAME
# The directory from which sbatch was invoked (e.g. proj/DBN/src/data/RPP)
SERVERDIR=$SLURM_SUBMIT_DIR
# The working directory in the node named after the ID of the job allocation
NODEDIR="/tmp/work/SLURM_$SLURM_JOB_ID"
#NODEDIR="$SLURM_SCRATCH/work/SLURM_$SLURM_JOB_ID"
mkdir -p $NODEDIR
cd $NODEDIR

NCPU=`scontrol show hostnames $SLURM_JOB_NODELIST | wc -l`
echo ------------------------------------------------------
echo ' This job is allocated on '$NCPU' cpu(s)'
echo ------------------------------------------------------
echo SLURM: sbatch is running on $SERVER
echo SLURM: server calling directory is $SERVERDIR
echo SLURM: node is $NODE
echo SLURM: node working directory is $NODEDIR
echo SLURM: job identifier is $SLURM_JOBID
echo SLURM: job name is $SLURM_JOB_NAME
echo SLURM: job array identifier is $SLURM_ARRAY_TASK_ID
echo ' '
echo ' '

# This function gets called by opts_ParseArguments when --help is specified
usage() {
    # header text
    echo "
        $log_ToolName: Queueing script for running RPP on Slurm-based computing clusters

        Usage: $log_ToolName --studyFolder=<path to the folder with subject images>
                             --subjects=<file or list of subject IDs>
                             [--b0=<scanner magnetic field intensity] default=3T
                             [--linear=<select (non)linear registered image>] default=yes
                             [--debugMode=<do(non) perform a dry run>] default=yes

        PARAMETERs are [ ] = optional; < > = user supplied value

        Values default to running the example with sample data
    "
    # automatic argument descriptions
    opts_ShowArguments
}

input_parser() {
    # Load input parser functions
    # Change this for ssh commands
    setup=$( cd "$SERVERDIR" ; pwd )
    cd $SERVERDIR
    . "${setup}/setUpRPP.sh"
    . "${DBN_Libraries}/newopts.shlib" "$@"
    cd $NODEDIR

    opts_AddMandatory '--studyFolder' 'studyFolder' 'raw data folder path' "a required value; is the path to the study folder holding the raw data. Don't forget the study name (e.g. /mnt/storinator/edd32/data/raw/ADNI)"
    opts_AddMandatory '--subjects' 'subjects' 'path to file with subject IDs' "an required value; path to a file with the IDs of the subject to be processed (e.g. /mnt/storinator/edd32/data/raw/ADNI/subjects.txt)" "--subject" "--subjectList" "--subjList"
    opts_AddOptional  '--b0' 'b0' 'magnetic field intensity' "an optional value; the scanner magnetic field intensity, e.g., 1.5T, 3T, 7T" "3T"
    opts_AddOptional  '--linear'  'linear' '(non)linear registration to MNI' "an optional value; if it is set then only an affine registration to MNI is performed, otherwise, a nonlinear registration to MNI is performed" "yes"
    opts_AddOptional  '--debugMode' 'PRINTCOM' 'do (not) perform a dray run' "an optional value; If PRINTCOM is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the PRINTCOM variable, e.g., echo" "" "--PRINTCOM" "--printcom"
    opts_ParseArguments "$@"
    #studyFolder=$studyFolder
    #subjects=$subjects
    #b0=$b0
    #linear=$linear
    #debugMode=$PRINTCOM
    # Display the parsed/default values
    opts_ShowValues
}


setup() {
    # Looks in the file of IDs and get the correspoding subject ID for this job
    SUBJECTID=$(head -n $SLURM_ARRAY_TASK_ID "$subjects" | tail -n 1)
    # The directory holding the data for the subject correspoinding ot this job
    SUBJECTDIR=$studyFolder/raw/$SUBJECTID

    echo Transferring files from server to compute node $NODE
    # Copy RPP scripts and DATA from server to node, creating whatever directories required
    $SCP -r $SERVER:$SERVERDIR $NODE:$NODEDIR
    $SCP -r $SERVER:$SUBJECTDIR $NODE:$NODEDIR

    #echo Files in node work directory are as follows:
    #$SSH $NODE "ls -lahR $NODEDIR"

    # Location of subject folders (named by subjectID)
    studyFolderBasename=`basename $studyFolder`;

    # Report major script control variables to usertart_auto_complete)cho "studyFolder: ${SERVERDATADIR}"
	echo "subject:${SUBJECTID}"
	echo "environmentScript: ${setup}/setUpRPP.sh"
	echo "b0: ${b0}"
	echo "linear: ${linear}"
	echo "debugMode: ${PRINTCOM}"

    # Create log folder
    LOGDIR="${NODEDIR}/logs/${studyFolderBasename}/RPP/${SUBJECTID}/${b0}"
    $SSH $NODE "mkdir -p $LOGDIR"

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
    # Hires MNI brain mask template
    TemplateMask="${MNI_Templates}/MNI152_T1_0.7mm_brain_mask.nii.gz"
    # Lowres MNI brain mask template
    Template2mmMask="${MNI_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz"

    # Other Config Settings
    # BrainSize in mm, 150 for humans
    BrainSize="150"
    # FNIRT 2mm T1w Config
    FNIRTConfig="${RPP_Config}/T1_2_MNI152_2mm.cnf"
}

main() {
    ###############################################################################
	# Inputs:
	#
	# Scripts called by this script do NOT assume anything about the form of the
	# input names or paths. This batch script assumes the following raw data naming
	# convention, e.g.
	#
	# ${SUBJECTID}/{b0}/T1w_MPR1/${SUBJECTID}_{b0}_T1w_MPR1.nii.gz
	# ${SUBJECTID}/{b0}/T1w_MPR2/${SUBJECTID}_{b0}_T1w_MPR2.nii.gz
    # ...
	# ${SUBJECTID}/{b0}/T1w_MPRn/${SUBJECTID}_{b0}_T1w_MPRn.nii.gz
    ###############################################################################

    # Detect Number of T1w Images and build list of full paths to T1w images
    numT1ws=`ls ${SUBJECTDIR}/${b0} | grep 'T1w_MPR.$' | wc -l`
    echo "Found ${numT1ws} T1w Images for subject ${SUBJECTID}"
    T1wInputImages=""
    i=1
    while [ $i -le $numT1ws ] ; do
        # An @ symbol separate the T1-weighted image's full paths
        T1wInputImages=`echo "${T1wInputImages}${SUBJECTDIR}/${b0}/T1w_MPR${i}/${SUBJECTID}_${b0}_T1w_MPR${i}.nii.gz@"`
        i=$(($i+1))
    done

    # Detect Number of T2w Images and build list of full paths to T2w images
    numT2ws=`ls ${SUBJECTID}/${b0} | grep 'T2w_SPC.$' | wc -l`
    echo "Found ${numT2ws} T2w Images for subject ${SUBJECTID}"
    T2wInputImages=""
    i=1
    while [ $i -le $numT2ws ] ; do
        # An @ symbol separate the T2-weighted image's full paths
        T2wInputImages=`echo "${T2wInputImages}${SUBJECTID}/${b0}/T2w_SPC${i}/${SUBJECTID}_${b0}_T2w_SPC${i}.nii.gz@"`
        i=$(($i+1))
    done

    cd $NODEDIR

    # Submit to be run the RPP.sh script with all the specified parameter values
    ./RPP/RPP.sh \
        --studyName="$studyFolderBasename" \
        --subject="$SUBJECTID" \
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
        --FNIRTConfig="$FNIRTConfig" \
        --printcom=$PRINTCOM \
        1> $LOGDIR/$SUBJECTID.out \
        2> $LOGDIR/$SUBJECTID.err
}

cleanup() {
	echo ' '
	echo Transferring files from node to server
	echo "Writing files in permanent directory ${studyFolder}/preprocessed/RPP/${SUBJECTID}"

    $SCP -r ${NODE}:${NODEDIR}/logs ${SERVER}:${studyFolder}
    $SSH ${SERVER} "mkdir -p ${studyFolder}/preprocessed/RPP/${SUBJECTID}"
    $SCP -r ${NODE}:${NODEDIR}/tmp/${studyFolderBasename}/preprocessed/RPP/${SUBJECTID}/${b0} ${SERVER}:${studyFolder}/preprocessed/RPP/${SUBJECTID}
    $SCP -r ${SERVER}:${SERVERDIR}/logs/slurm ${SERVER}:${studyFolder}/logs

    echo Files transfered to permanent directory, clean temporary directory
    rm -rf /tmp/work/SLURM_$SLURM_JOB_ID
}

early() {
	echo ' '
	echo ' ############ WARNING:  EARLY TERMINATION #############'
	echo ' '
}

input_parser "$@"
setup
main
cleanup

trap 'early; cleanup' SIGINT SIGKILL SIGTERM SIGSEGV

# happy end
exit 0
