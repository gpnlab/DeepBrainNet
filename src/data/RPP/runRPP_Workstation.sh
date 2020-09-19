#!/bin/bash

set -eu

# Load input parser functions
setup=$( cd "$(dirname "$0")" ; pwd )
. "${setup}/setUpRPP.sh"
. "${DBN_Libraries}/newopts.shlib" "$@"

get_subjList() {
    file_or_list=$1
    subjList=""
    # If a file with the subject ID was passed
    if [ -f "$file_or_list" ] ; then
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

# This function gets called by opts_ParseArguments when --help is specified
usage() {
    # header text
    echo "
        $log_ToolName: Submitting script for running RPP on Slurm managed computing clusters

        Usage: $log_ToolName [--job-name=<name for job allocation>] default=ADNI_LinearRPP
                             [--partition=<request a specific partition>] default=workstation
                             [--exclude=<node(s) to be excluded>] default=""
                             [--nodes=<minimum number of nodes allocated to this job>] default="1"
                             [--time=<limit on the total run time of the job allocation>] default="1"
                             [--ntasks=<maximum number of tasks>] default=1
                             [--mem=<specify the real memory required per node>] default=2gb
                             [--export=<export environment variables>] default=ALL
                             [--mail-type=<type of mail>] default=FAIL,END
                             [--mail-user=<user email>] default=eduardojdiniz@gmail.com
                             --studyFolder=<path to folder holding the raw data folder> It assumes data is stored in raw folder e.g. /mnt/storinator/edd32/data/ADNI>
                             --subjects=<file or list of subject IDs> e.g. /mnt/storinator/edd32/data/ADNI/raw/ID_list.txt
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

    opts_AddOptional '--job-name' 'jobName' 'name for job allocation' "an optional value; specify a name for the job allocation. Default: ADNI_LinearRPP" "ADNI_LinearRPP"
    opts_AddOptional '--partition' 'partition' 'request a specifi partition' "an optional value; request a specific partition for the resource allocation (e.g. standard, workstation). Default: standard" "workstation"
    opts_AddOptional  '--exclude' 'exclude' 'node to be excluded' "an optional value; Explicitly exclude certain nodes from the resources granted to the job. Default: None" ""
    opts_AddOptional  '--nodes' 'nodes' 'minimum number of nodes allocated to this job' "an optional value; iIf a job node limit exceeds the number of nodes configured in the partiition, the job will be rejected. Default: 1" "1"
    opts_AddOptional  '--time' 'time' 'limit on the total run time of the job allocation' "an optional value; When the time limit is reached, each task in each job step is sent SIGTERM followed by SIGKILL. Format: days-hours:minutes:seconds. Default 2 hours: None" "0-02:00:00"
    #opts_AddOptional  '--nodelist' 'nodeList' 'request a specific list of hosts' "an optional value;The job will contain all of these hosts and possibly additional hosts as needed to satisfy resource requirements. The list may be specified as a comma-separated list of hosts, a range of hosts (host[1-5,7,...] for example), or a filename. The host list will be assumed to be a filename if it contains a "/" character. If you specify a minimum node or processor count larger than can be satisfied by the supplied host list, additional resources will be allocated on other nodes as needed. Duplicate node names in the list will be ignored. The order of the node names in the list is not important; the node names will be sorted by Slurm. Default: None" ""
    opts_AddOptional '--ntasks' 'nTasks' 'maximum number tasks' "an optional value; sbatch does not launch tasks, it requests an allocation of resources and submits a batch script. This option advises the Slurm controller that job steps run within the allocation will launch a maximum of number tasks and to provide for sufficient resources. Default: 1" "1"
    #opts_AddOptional '--cpus-per-task' 'CPUsPerTask' 'required ncpus number of processors per task' "an optional value; an optional value; advise the Slurm controller that ensuing job steps will require ncpus number of processors per task. Default: 1" "1"
    #opts_AddOptional  '--mem-per-cpu' 'memPerCPU' 'minimum memory allocated memory per CPU' "an optional value; specify the minimum real memory required per CPU. Default: 4gb" "2000"
    opts_AddOptional  '--mem' 'mem' 'specify the real memory requried per node' "an optional value; specify the real memory required per node. Default: 2gb" "2gb"
    opts_AddOptional  '--export' 'export' 'export environment variables' "an optional value; Identify which environment variables from the submission environment are propagated to the launched application. Note that SLURM_* variables are always propagated. Default: All of the users environment will be loaded (either from callers environment or clean environment" "ALL"
    opts_AddOptional  '--mail-type' 'mailType' 'type of mail' "an optional value; notify user by email when certain event types occur. Default: FAIL,END" "FAIL,END"
    opts_AddOptional  '--mail-user' 'mailUser' 'user email' "an optional value; User to receive email notification of state changes as defined by --mail-type. Default: eduardojdiniz@gmail.com" "eduardojdiniz@gmail.com"
    #opts_AddOptional  '--output' 'output' 'where to save standard output' "an optional value; Instruct Slurm to connect the batch scrpit's standard output directly to the file name specified. Default: $NODEDIR" "$NODEDIR"
    #opts_AddOptional  '--error' 'error' 'where to save standard error' "an optional value; Instruct Slurm to connect the batch scrpit's standard error directly to the file name specified. Default: $NODEDIR" "$NODEDIR"
    opts_AddMandatory '--studyFolder' 'studyFolder' 'raw data folder path' "a required value; is the path to the study folder holding the raw data. Don't forget the study name (e.g. /home/edd32/data/raw/ADNI)"
    opts_AddMandatory '--subjects' 'subjects' 'path to file with subject IDs' "an required value; path to a file with the IDs of the subject to be processed (e.g. /home/edd32/data/raw/ADNI/subjects.txt)" "--subject" "--subjectList" "--subjList"
    opts_AddOptional  '--b0' 'b0' 'magnetic field intensity' "an optional value; the scanner magnetic field intensity, e.g., 1.5T, 3T, 7T" "7T"
    opts_AddOptional  '--linear'  'linear' '(non)linear registration to MNI' "an optional value; if it is set then only an affine registration to MNI is performed, otherwise, a nonlinear registration to MNI is performed" "yes"
    opts_AddOptional  '--debugMode' 'PRINTCOM' 'do (not) perform a dray run' "an optional value; If PRINTCOM is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the PRINTCOM variable, e.g., echo" "" "--PRINTCOM" "--printcom"

    opts_ParseArguments "$@"

    # Get an index for each subject ID; It will be used to submit an array job
    get_subjList $subjects
    delim=""
    array=""
    i=1
    for id in $subjList ; do
        array="$array$delim$i"
        delim=","
		i=$(($i+1))
    done

    # Display the parsed/default values
    opts_ShowValues

    # Make slurm logs directory
    mkdir -p "$(dirname "$0")"/logs/slurm

	queuing_command="sbatch \
        --job-name=$jobName \
        --partition=$partition \
        --exclude=$exclude \
        --nodes=$nodes \
        --time=$time \
        --ntasks=$nTasks \
        --export=$export \
        --mail-type=$mailType \
        --mail-user=$mailUser \
        --mem=$mem \
        --array=$array"

    ${queuing_command} RPP_Workstation.sh \
          --studyFolder=$studyFolder \
          --subjects=$subjects \
          --b0=$b0 \
          --linear=$linear \
          --debugMode=$PRINTCOM
}

input_parser "$@"
