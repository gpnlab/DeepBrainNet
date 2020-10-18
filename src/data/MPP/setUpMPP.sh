#!/bin/echo This script should be sourced before calling a pipeline script, and should not be run directly:

# Get absolute path of setUpMPP.sh
globalSetup="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Get path to src
globalSetup=$( dirname "$(dirname "$globalSetup")" )
# Get absolute path of setUpDBN.sh
globalSetup="$globalSetup"/global/config/setUpDBN.sh

# Source global variables
. "$globalSetup"

# Path to the FNIRT configuration
export MPP_Config="${MPPDIR}/config"
# Location of sub-scripts that are used to carry out some steps of the MPP.sh
export MPP_Scripts="${MPPDIR}/scripts"
