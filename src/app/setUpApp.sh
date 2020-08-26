#!/bin/echo This script should be sourced before calling a pipeline script, and should not be run directly:

# Get absolute path of setUpRPP.sh
globalSetup="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#globalSetup=$( cd "$(dirname "$0")" ; pwd )
# Get path to src
globalSetup=$( dirname "$globalSetup" )
# Get absolute path of setUpDBN.sh
globalSetup="$globalSetup"/global/config/setUpDBN.sh
# Source global variables
. "$globalSetup"

# Path to app configuration
export APP_Config="${APPDIR}/config"
# Location of sub-scripts that are used to carry out some steps of prediction.sh
export APP_Scripts="${APPDIR}/scripts"
