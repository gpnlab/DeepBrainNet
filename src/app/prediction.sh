#!/bin/bash
set -eu

source "${PWD}/setUpApp.sh"
source "${DBN_Libraries}/newopts.shlib" "$@"

#this function gets called by opts_ParseArguments when --help is specified
function usage()
{
    #header text
    echo "
$log_ToolName: Predict brain age given a brain extracted, MNI registered T1w Image

Usage: $log_ToolName --studyFolder=<path to study folder>
                     [--subjects=<path to file or list of subject IDs>]
                     [--model=<path to the .h5 neural network model>]
                     [--output=<path to output csv file>]

PARAMETERs are [ ] = optional; < > = user supplied value

Values default to running the example with sample data
"
    #automatic argument descriptions
    opts_ShowArguments
}

function main()
{
    #arguments to opts_Add*: switch, variable to set, name for inside of <> in help text, description, [default value if AddOptional], [compatibility flag], ...
    #opts_AddOptional '--foo' 'myfoo' 'my foo' "give me a value, and i'll store it in myfoo" 'defaultfoo' '--oldoptionname' '--evenoldername'
    #opts_AddMandatory '--bar' 'mybar' 'your bar' "a required value, and this description is really long, but the opts_ShowArguments function automatically splits at spaces, or hyphenates if there aren't enough spaces"
    opts_AddMandatory '--study' 'studyFolder' 'study folder path' "a required value, and is the path to the study folder holding the preprocessed data" "--studyFolder"
    opts_AddMandatory '--subjects' 'subjects' 'path to file or list of subject IDs' "a required value, path to a file or a list of subject IDs to be processed" "--subject" "--subjectList" "--subjList"
    opts_AddOptional '--model' 'model' 'path to .h5 model' "an optional value, path to the model.h5 file" "${DBNDIR}/models/DBN_model.h5"
    opts_AddMandatory '--output' 'output' 'path to output file' "a required value, the output csv file that will hold the brain age predictions" "--out"
    opts_ParseArguments "$@"

    #display the parsed/default values
    opts_ShowValues

    #processing code goes here
}

if (($# == 0)) || [[ "$1" == --* ]]
then
    #named parameters
    main "$@"
else
    #positional support goes here - just call main with named parameters built from $1, etc
    log_Err_Abort "positional parameter support is not currently implemented"
    main --studyFolder="$1" --subjects="$2" --model="$3" --output="$4"
fi
