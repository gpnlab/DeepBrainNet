#!/bin/echo This script should be sourced before calling a pipeline script, and should not be run directly:

# Set up specific environment variables for the RPP
export FSL_FIXDIR=/usr/local/fix


# Set up FSL (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the FSLDIR setting for your setup
#export FSLDIR=/usr/local/fsl
#source "$FSLDIR/etc/fslconf/fsl.sh"

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

#add the specified version to the front of $PATH, so we can stop using absolute paths everywhere

# extra setup bits that the user should never need to edit

#make sure fsl generates .nii.gz files
export FSLOUTPUTTYPE=NIFTI_GZ

#try to reduce strangeness from locale and other environment settings
export LC_ALL=C
export LANGUAGE=C
#POSIXLY_CORRECT currently gets set by many versions of fsl_sub, unfortunately, but at least don't pass it in if the user has it set in their usual environment
unset POSIXLY_CORRECT

export DBNDIR="${HOME}/proj/DBN"
# Location of bash libraries that hold helper functions for the RPP.sh
export DBN_Libraries="${DBNDIR}/src/global/libs"
export RPPDIR="${DBNDIR}/src/data/RPP"
# Path to the MNI templates
export MNI_Templates="${DBNDIR}/data/external/templates"
# Path to the FNIRT configuration
export RPP_Config="${RPPDIR}/config"
# Location of sub-scripts that are used to carry out some steps of the RPP.sh
export RPP_Scripts="${RPPDIR}/scripts"
