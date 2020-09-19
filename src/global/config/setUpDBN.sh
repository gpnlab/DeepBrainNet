#!/bin/echo This script should be sourced before calling a pipeline script, and should not be run directly:
DBNDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export DBNDIR=$(dirname "$(dirname "$(dirname "$DBNDIR")")")


# Uncomment the following line (remove the leading #) and correct the DBNDIR setting for your setup
#export DBNDIR="${HOME}/proj/DBN"

# Set up FSL (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the FSLDIR setting for your setup
#export FSLDIR=/usr/local/fsl
#source "$FSLDIR/etc/fslconf/fsl.sh"

# Set up MATLAB (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the MATLABDIR setting for your setup
#export MATLABDIR=/usr/local/MATLAB/R2020a/bin
#export MATLABCMD=/usr/local/MATLAB/R2020a/bin/glnxa64/MATLAB

# Set up SPM12 (if not already done so in the running environment)
# Uncomment the following line (remove the leading #) and correct the SPM12DIR setting for your setup
export SPM12DIR=$HOME/spm12

export DBN_Libraries="${DBNDIR}/src/global/libs"
# Location of the Registration based preprocessing pipeline
export RPPDIR="${DBNDIR}/src/data/RPP"
# Location of the application directory
export APPDIR="${DBNDIR}/src/app"
# Path to the MNI templates
export MNI_Templates="${DBNDIR}/data/external/templates"

# Set up specific environment variables for the RPP
export FSL_FIXDIR=/usr/local/fix

if [[ -z "${FSLDIR:-}" ]]
then
    found_fsl=$(which fslmaths || true)
    if [[ ! -z "$found_fsl" ]]
    then
        #like our scripts, assume $FSLDIR/bin/fslmaths (neurodebian doesn't follow this, so sanity check)
        export FSLDIR=$(dirname "$(dirname "$found_fsl")")
        #if we didn't have FSLDIR, assume we haven't sourced fslconf
        if [[ ! -f "$FSLDIR/etc/fslconf/fsl.sh" ]]
        then
            echo "FSLDIR was unset, and guessed FSLDIR ($FSLDIR) does not contain etc/fslconf/fsl.sh, please specify FSLDIR in the setup script" 1>&2
            exit 1
        else
            source "$FSLDIR/etc/fslconf/fsl.sh"
        fi
    else
        echo "fslmaths not found in \$PATH, please install FSL and ensure it is on \$PATH, or edit the setup script to specify its location" 1>&2
        exit 1
    fi
fi

# add the specified version to the front of $PATH, so we can stop using absolute paths everywhere

# extra setup bits that the user should never need to edit

#make sure fsl generates .nii.gz files
export FSLOUTPUTTYPE=NIFTI_GZ

#try to reduce strangeness from locale and other environment settings
export LC_ALL=C
export LANGUAGE=C
#POSIXLY_CORRECT currently gets set by many versions of fsl_sub, unfortunately, but at least don't pass it in if the user has it set in their usual environment
unset POSIXLY_CORRECT

# Location of bash libraries that hold helper functions for DBN shell scripts
