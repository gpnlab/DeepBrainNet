#!/bin/bash

# # # organize_HCP_unprocessed_data.sh
# ## Description
#
# Organize HCP unprocessed data into folder configuration accepted by the RPP
# batch submission scripts
#
# ## Prerequisites:
#
# ### Installed Software
#
# * [FSL][FSL] - FMRIB's Software Library (version 5.0.6)
#
# ### Environment Variables
#
# * DBNDIR
#
#   Location of RPP sub-scripts that are used to carry out some of steps of the RPP.
#
# * FSLDIR
#
#   Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
#   University
#
# ### Inputs/Outputs
#
# Command line arguments are used to specify the HCP folder path (--HCP-in),
# the path to the reorganized HCP folder (--HCP-out), and optional (--b0)
# magnetic field strength
#
# The main output directories are:
#
# Inputs:
#
# This batch script assumes the HCP raw data naming convention, e.g.
#
# ${HCP_in}/${Subject}/release-nodes/Structural_unproc.txt
# ${HCP_in}/${Subject}/unprocessed/${b0}/{Subject}_${b0}.csv
#
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR1/${Subject}_${b0}_T1w_MPR1.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR1/${Subject}_${b0}_AFI.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR1/${Subject}_${b0}_BIAS_32CH.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR1/${Subject}_${b0}_BIAS_BC.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR1/${Subject}_${b0}_FieldMap_Magnitude.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR1/${Subject}_${b0}_FieldMap_Phase.nii.gz
#
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR2/${Subject}_${b0}_T1w_MPR2.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR2/${Subject}_${b0}_AFI.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR2/${Subject}_${b0}_BIAS_32CH.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR2/${Subject}_${b0}_BIAS_BC.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR2/${Subject}_${b0}_FieldMap_Magnitude.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_MPR2/${Subject}_${b0}_FieldMap_Phase.nii.gz
#
# ${HCP_in}/${Subject}/unprocessed/${b0}/T2w_SPC1/${Subject}_${b0}_T2w_SPC1.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC1/${Subject}_${b0}_AFI.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC1/${Subject}_${b0}_BIAS_32CH.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC1/${Subject}_${b0}_BIAS_BC.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC1/${Subject}_${b0}_FieldMap_Magnitude.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC1/${Subject}_${b0}_FieldMap_Phase.nii.gz
#
# ${HCP_in}/${Subject}/unprocessed/${b0}/T2w_SPC2/${Subject}_${b0}_T2w_SPC2.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC2/${Subject}_${b0}_AFI.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC2/${Subject}_${b0}_BIAS_32CH.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC2/${Subject}_${b0}_BIAS_BC.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC2/${Subject}_${b0}_FieldMap_Magnitude.nii.gz
# ${HCP_in}/${Subject}/unprocessed/${b0}/T1w_SPC2/${Subject}_${b0}_FieldMap_Phase.nii.gz
#
# Outputs:
#
# This script outputs assuming the RPP raw data naming convention, e.g.
#
# ${HCP_out}/${Subject}/${b0}/T1w_MPR1/${Subject}_${b0}_T1w_MPR1.nii.gz
# ${HCP_out}/${Subject}/${b0}/T1w_MPR2/${Subject}_${b0}_T1w_MPR2.nii.gz
#
# ${HCP_out}/${Subject}/${b0}/T2w_SPC1/${Subject}_${b0}_T2w_SPC1.nii.gz
# ${HCP_out}/${Subject}/${b0}/T2w_SPC2/${Subject}_${b0}_T2w_SPC2.nii.gz
#
# <!-- References -->
# [FSL]: http://fsl.fmrib.ox.ac.uk

set -eu

RSYNC=/usr/bin/rsync

setup=$( cd "$(dirname "$0")" ; pwd )
. "${setup}/setUpRPP.sh"

# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------

. "${DBN_Libraries}/log.shlib" "$@"
. "${DBN_Libraries}/newopts.shlib" "$@"

log_Check_Env_Var FSLDIR

# ------------------------------------------------------------------------------
#  Usage Description Function
# ------------------------------------------------------------------------------

# This function gets called by opts_ParseArguments when --help is specified
function usage() {
    # header text
    echo "
        $log_ToolName: Organize HCP unprocessed data into folder configuration
        accepted by the RPP batch submission scripts
        Usage: $log_ToolName --HCP-in=<path to the folder with subject images>
                             --HCP-out=<path to the folder with reorganized subject images>
                             [--b0=<magnetic field intensity>]. Default: 3T

        PARAMETERs are [ ] = optional; < > = user supplied value

        Values default to running the example with sample data
    "
    # automatic argument descriptions
    opts_ShowArguments
}

function main() {
    opts_AddMandatory '--HCP-in' 'HCP_in' 'path to the folder with subject images'  'a required value; path to the folder with subject images with HCP raw data naming convention' "--HCPin" "--HCPIn" "--HCPIN"  "--HCP-In" "--HCP-IN" "hcp-in"
    opts_AddMandatory '--HCP-out' 'HCP_out' 'path to the folder with reorganized subject images'  'a required value; path to the folder with reorganized subject images according to the RPP raw data naming convention' "--HCPout" "--HCPOut" "--HCPOUT" "--HCP-Out" "--HCP-OUT" "hcp-out"
    opts_AddOptional  '--b0' 'b0' 'magnetic field intensity' "an optional value; the scanner magnetic field intensity, e.g., 1.5T, 3T, 7T" "3T"

    opts_ParseArguments "$@"

    # Display the parsed/default values
    opts_ShowValues

    # Get subject list
    #subjList=$(ls -1 $HCP_in)
    subjList=$(find $HCP_in -maxdepth 1 -type d -printf "%f\n")

    echo -e "\nCycling through subject list\n"
	# Cycle through specified subjects
	for subject in $subjList ; do

		echo -e "Subject $subject"

		# Input Images

		# Detect Number of T1w Images and build list of full paths to T1w images
		numT1ws=`ls ${HCP_in}/${subject}/unprocessed/${b0} | grep 'T1w_MPR.$' | wc -l`
		echo "Found ${numT1ws} T1w Images for subject ${subject}"
		i=1
		while [ $i -le $numT1ws ] ; do
            mkdir -p ${HCP_out}/${subject}/T1w_MPR${i}
            rsync -azh ${HCP_in}/${subject}/unprocessed/${b0}/T1w_MPR${i}/${subject}_${b0}_T1w_MPR${i}.nii.gz \
                        ${HCP_out}/${subject}/T1w_MPR${i}/${subject}_${b0}_T1w_MPR${i}.nii.gz
            #cp ${HCP_in}/${subject}/unprocessed/${b0}/T1w_MPR${i}/${subject}_${b0}_T1w_MPR${i}.nii.gz \
            #            ${HCP_out}/${subject}/T1w_MPR${i}/${subject}_${b0}_T1w_MPR${i}.nii.gz
			i=$(($i+1))
		done

		# Detect Number of T1w Images and build list of full paths to T1w images
		numT2ws=`ls ${HCP_in}/${subject}/unprocessed/${b0} | grep 'T2w_SPC.$' | wc -l`
		echo "Found ${numT2ws} T2w Images for subject ${subject}"
		i=1
		while [ $i -le $numT2ws ] ; do
            mkdir -p ${HCP_out}/${subject}/T2w_SPC${i}
            rsync -azh ${HCP_in}/${subject}/unprocessed/${b0}/T2w_SPC${i}/${subject}_${b0}_T2w_SPC${i}.nii.gz \
                        ${HCP_out}/${subject}/T2w_SPC${i}/${subject}_${b0}_T2w_SPC${i}.nii.gz
            #cp ${HCP_in}/${subject}/unprocessed/${b0}/T2w_SPC${i}/${subject}_${b0}_T2w_SPC${i}.nii.gz \
            #            ${HCP_out}/${subject}/T2w_SPC${i}/${subject}_${b0}_T2w_SPC${i}.nii.gz
			i=$(($i+1))
		done

	done
}

main "$@"
