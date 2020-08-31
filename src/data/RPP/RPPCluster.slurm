#!/bin/bash

set -eu

RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh

# The hostname from which sbatch was invoked (e.g. storinator)
SERVER=$SLURM_SUBMIT_HOST
# The name of the nome running the job script (e.g. obelix)
NODE=$SLURMD_NODENAME
# The directory from which sbatch was invoked (e.g. proj/DBN/src/data/RPP)
SERVERDIR=$SLURM_SUBMIT_DIR
# The working directory in the node named after the ID of the job allocation
NODEDIR="/global/work/${USER}/SLURM_$SLURM_JOB_ID"

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

# Load input parser functions
setup=$( cd "$SERVERDIR" ; pwd )
. "${setup}/setUpRPP.sh"
. "${DBN_Libraries}/newopts.shlib" "$@"

# This function gets called by opts_ParseArguments when --help is specified
usage() {
    # header text
    echo "
        $log_ToolName: Batch script for running RPPBatch on Slurm

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
    #opts_AddOptional '--job-name' 'job-name' 'name for job allocation' "an optional value; specify a name for the job allocation. Default: RPP" "RPP_${SUBJECTID}"
    #opts_AddOptional '--partition' 'partition' 'request a specifi partition' "an optional value; request a specific partition for the resource allocation (e.g. standard, workstation). Default: standard" "standard"
    #opts_AddMandatory '--ntasks' 'ntasks' 'maximum number tasks' "a required value; sbatch does not launch tasks, it requests an allocation of resources and submits a batch script. This option advises the Slurm controller that job steps run within the allocation will launch a maximum of number tasks and to provide for sufficient resources"
    #opts_AddOptional '--cpus-per-task' '--cpus-per-task' 'required ncpus number of processors per task' "an optional value; an optional value; advise the Slurm controller that ensuing job steps will require ncpus number of processors per task. Default: 1" "1"
    #opts_AddOptional  '--mem-per-cpu' 'mem-per-cpu' 'minimum memory allocated memory per CPU' "an optional value; specify the minimum real memory required per CPU. Default: 4gb" "4G"
    #opts_AddOptional  '--export' 'export' 'export environment variables' "an optional value; Identify which environment variables from the submission environment are propagated to the launched application. Note that SLURM_* variables are always propagated. Default: All of the users environment will be loaded (either from callers environment or clean environment" "ALL"
    #opts_AddOptional  '--mail-type' 'mail-type' 'type of mail' "an optional value; notify user by email when certain event types occur. Default: FAIL,END" "FAIL,END"
    #opts_AddOptional  '--mail-user' 'mail-user' 'user email' "an optional value; User to receive email notification of state changes as defined by --mail-type. Default: eduardojdiniz@gmail.com" "eduardojdiniz@gmail.com"
    #opts_AddOptional  '--output' 'output' 'where to save standard output' "an optional value; Instruct Slurm to connect the batch scrpit's standard output directly to the file name specified. Default: $NODEDIR" "$NODEDIR"
    #opts_AddOptional  '--error' 'error' 'where to save standard error' "an optional value; Instruct Slurm to connect the batch scrpit's standard error directly to the file name specified. Default: $NODEDIR" "$NODEDIR"
    opts_AddMandatory '--studyFolder' 'studyFolder' 'raw data folder path' "a required value; is the path to the study folder holding the raw data. Don't forget the study name (e.g. /home/edd32/data/raw/ADNI)"
    opts_AddMandatory '--subjects' 'subjects' 'path to file with subject IDs' "an required value; path to a file with the IDs of the subject to be processed (e.g. /home/edd32/data/raw/ADNI/subjects.txt)" "--subject" "--subjectList" "--subjList"
    opts_AddOptional  '--b0' 'b0' 'magnetic field intensity' "an optional value; the scanner magnetic field intensity, e.g., 1.5T, 3T, 7T" "3T"
    opts_AddOptional  '--linear'  'linear' '(non)linear registration to MNI' "an optional value; if it is set then only an affine registration to MNI is performed, otherwise, a nonlinear registration to MNI is performed" "yes"
    opts_AddOptional  '--debugMode' 'PRINTCOM' 'do (not) perform a dray run' "an optional value; If PRINTCOM is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the PRINTCOM variable, e.g., echo" "" "--PRINTCOM" "--printcom"

    opts_ParseArguments "$@"

    # Display the parsed/default values
    opts_ShowValues
}


setup() {
    # Looks in the file of IDs and get the correspoding subject ID for this job
    SUBJECTID=$(head -n $SLURM_ARRAY_TASK_ID "$subjects" | tail -n 1)
    # The directory holding the data for the subject correspoinding ot this job
    SUBJECTDIR=$SERVERDATADIR/$SUBJECTID

    echo Transferring files from server to compute node $NODE
    # Copy RPP scripts and DATA from server to node, creating whatever directories required
    $RSYNC -r $SERVERDIR $NODE:$NODEDIR
    $RSYNC -r $SUBJECTDIR $NODE:$NODEDIR

    echo Files in node work directory are as follows:
    $SSH $NODE "ls -lahR $NODEDIR"

    # The directory holding all subjects data e.g. "storinator:/home/edd32/data/raw/ADNI"
    SERVERDATADIR=$studyFolder

    # Location of subject folders (named by subjectID)
    studyFolderBasename=`basename $SERVERDATADIR`;


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

    # Submit to be run the RPP.sh script with all the specified parameter values
    ./RPP/RPP.sh \
        --studyFolder="$studyFolderBasename" \
        --subject="$SUBJECTID" \
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
        --printcom=$PRINTCOM
        1> "$LOGDIR"/"$SUBJECTID".out \
        2> "$LOGDIR"/"$SUBJECTID".err
}

cleanup() {
	echo ' '
	echo Transferring files from node to server
	echo Writing files in permanent directory  $SERVERDIR
	cd $NODEDIR

    $RSYNC -r $SUBJECTDIR $SERVER:data/preprocessed/$studyFolderBasename
    $RSYNC -r logs/ $SERVER:data/logs/

	echo Final files in permanent data directory:
	$SSH $SERVER "cd data/preprocessed/$studyFolderBasename; ls -lah"
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
