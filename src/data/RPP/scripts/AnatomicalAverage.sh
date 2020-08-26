#!/bin/bash

set -eu

# ------------------------------------------------------------------------------
#  Verify required environment variables are set
# ------------------------------------------------------------------------------

if [ -z "${MNI_Templates}" ]; then
	echo "$(basename ${0}): ABORTING: MNI_Templates environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): MNI_Templates: ${MNI_Templates}"
fi

if [ -z "${DBN_Libraries}" ]; then
	echo "$(basename ${0}): ABORTING: DBN_Libraries environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): DBN_Libraries: ${DBN_Libraries}"
fi

if [ -z "${FSLDIR}" ]; then
	echo "$(basename ${0}): ABORTING: FSLDIR environment variable must be set"
	exit 1
else
	echo "$(basename ${0}): FSLDIR: ${FSLDIR}"
fi

# ------------------------------------------------------------------------------
# Support functions
# ------------------------------------------------------------------------------

. "${DBN_Libraries}/log.shlib" # Logging related functions
. "${DBN_Libraries}/newopts.shlib" "$@" # argument parser

#this function gets called by opts_ParseArguments when --help is specified
function usage() {
    #header text
    echo "
        $log_ToolName: Perform simple average of an array of TXw images

        Usage: $log_ToolName [--workingDir=""<local, temporary working directory>]
                             --imageList=<list of image paths; must be at least 2>
                             [--ref=MNI152_T1_2mm.nii.gz<standard image>]
                             [--refMask=MNI152_T1_2mm_brain_mask_dil.nii.gz <standard brain mask>]
                             --output=<output basename>
                             [--brainSize=150mm <average brain size>]
                             [--crop=yes<do (not) crop images>]
                             [--clean=yes<do (not) run the cleanup of working directory>]
                             [--verbose=no<do (not) verbose output>]

        PARAMETERs are [ ] = optional; < > = user supplied value

        Values default to running the example with sample data
    "
    #automatic argument descriptions
    opts_ShowArguments
}

function main()
{
    opts_AddOptional '--workingDir' 'wdir' 'temporary working directory' "an optional value; is the path to the local, temporary working directory where the byproducts of this script will be stored" ""  "--workingdir"  "--wdir"
    opts_AddMandatory  '--imageList' 'imagelist' 'list of image paths' "a required value; a list, of at least two image paths, that will be anatomically averaged"
    opts_AddOptional  '--ref' 'StandardImage' 'path to standard image' "an optional value; path to standard image (e.g. MNI152_T1_2mm)" "${MNI_Templates}/MNI152_T1_2mm.nii.gz"
    opts_AddOptional  '--refMask' 'StandardMask' 'path to standard brain mask' "an optional value; path to standard brain maks (e.g. MNI152_T1_2mm_brain_mask_dil)" "${MNI_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz"
    opts_AddMandatory  '--out' 'output' 'output basename' "a required value; output basename for the anatomically averaged images"
    opts_AddOptional  '--brainSize' 'BrainSizeOpt' 'average brain size' "an optional value; average brain size in milimiteres" "150"
    opts_AddOptional  '--crop' 'crop' 'do (not) crop images' "an optional value; determine if images will be cropped" "yes"
    opts_AddOptional  '--clean' 'clean' 'do (not) clean working directory' "an optional value; determine if the working directory will be cleaned up" "yes"
    opts_AddOptional  '--verbose' 'verbose' 'do (not) verbose output' "an optional value; determine if the commands being runned will be logged" "no"
    opts_ParseArguments "$@"

    #display the parsed/default values
    opts_ShowValues

    # setup working directory
    if [ X$wdir = X ] ; then
        wdir=`$FSLDIR/bin/tmpnam`;
        wdir=${wdir}_wdir
    fi
    if [ ! -d $wdir ] ; then
        if [ -f $wdir ] ; then
            log_Err_Abort "A file already exists with the name $wdir - cannot use this as the working directory"
        fi
        mkdir $wdir
    fi

    if [ `echo $imagelist | wc -w` -lt 2 ] ; then
        Usage;
        log_Err_Abort "Must specify at least two images to average"
    fi

    # process imagelist
    newimlist=""
    for fn in $imagelist ; do
        bnm=`$FSLDIR/bin/remove_ext $fn`;
        bnm=`basename $bnm`;
        $FSLDIR/bin/imln $fn $wdir/$bnm   ## TODO - THIS FAILS WHEN GIVEN RELATIVE PATHS
        newimlist="$newimlist $wdir/$bnm"
    done

    if [ $verbose = yes ] ; then
        log_Msg "Images: $imagelist  Output: $output"
    fi

    # for each image reorient, register to std space, (optionally do "get transformed FOV and crop it based on this")
    for fn in $newimlist ; do
        $FSLDIR/bin/fslreorient2std ${fn}.nii.gz ${fn}_reorient
        $FSLDIR/bin/robustfov -i ${fn}_reorient -r ${fn}_roi -m ${fn}_roi2orig.mat $BrainSizeOpt
        $FSLDIR/bin/convert_xfm -omat ${fn}TOroi.mat -inverse ${fn}_roi2orig.mat
        $FSLDIR/bin/flirt -in ${fn}_roi -ref "$StandardImage" -omat ${fn}roi_to_std.mat -out ${fn}roi_to_std -dof 12 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
        $FSLDIR/bin/convert_xfm -omat ${fn}_std2roi.mat -inverse ${fn}roi_to_std.mat
    done

    # register images together, using standard space brain masks
    im1=`echo $newimlist | awk '{ print $1 }'`;
    for im2 in $newimlist ; do
        if [ $im2 != $im1 ] ; then
            # register version of two images (whole heads still)
            $FSLDIR/bin/flirt -in ${im2}_roi -ref ${im1}_roi -omat ${im2}_to_im1.mat -out ${im2}_to_im1 -dof 6 -searchrx -30 30 -searchry -30 30 -searchrz -30 30

            # transform std space brain mask
            $FSLDIR/bin/flirt -init ${im1}_std2roi.mat -in "$StandardMask" -ref ${im1}_roi -out ${im1}_roi_linmask -applyxfm

            # re-register using the brain mask as a weighting image
            $FSLDIR/bin/flirt -in ${im2}_roi -init ${im2}_to_im1.mat -omat ${im2}_to_im1_linmask.mat -out ${im2}_to_im1_linmask -ref ${im1}_roi -refweight ${im1}_roi_linmask -nosearch
        else
            cp $FSLDIR/etc/flirtsch/ident.mat ${im1}_to_im1_linmask.mat
        fi
    done

    # get the halfway space transforms (midtrans output is the *template* to halfway transform)
    translist=""
    for fn in $newimlist ; do
        translist="$translist ${fn}_to_im1_linmask.mat"
    done
    $FSLDIR/bin/midtrans --separate=${wdir}/ToHalfTrans --template=${im1}_roi $translist

    # interpolate
    n=1;
    for fn in $newimlist ; do
        num=`$FSLDIR/bin/zeropad $n 4`;
        n=`echo $n + 1 | bc`;
        if [ $crop = yes ] ; then
            $FSLDIR/bin/applywarp --rel -i ${fn}_roi --premat=${wdir}/ToHalfTrans${num}.mat -r ${im1}_roi -o ${wdir}/ImToHalf${num} --interp=spline
        else
            $FSLDIR/bin/convert_xfm -omat ${wdir}/ToHalfTrans${num}.mat -concat ${wdir}/ToHalfTrans${num}.mat ${fn}TOroi.mat
            $FSLDIR/bin/convert_xfm -omat ${wdir}/ToHalfTrans${num}.mat -concat ${im1}_roi2orig.mat ${wdir}/ToHalfTrans${num}.mat
            $FSLDIR/bin/applywarp --rel -i ${fn}_reorient --premat=${wdir}/ToHalfTrans${num}.mat -r ${im1}_reorient -o ${wdir}/ImToHalf${num} --interp=spline
        fi
    done

    # average outputs
    comm=`echo ${wdir}/ImToHalf* | sed "s@ ${wdir}/ImToHalf@ -add ${wdir}/ImToHalf@g"`;
    tot=`echo ${wdir}/ImToHalf* | wc -w`;
    $FSLDIR/bin/fslmaths ${comm} -div $tot ${output}



    # CLEANUP
    if [ $cleanup != no ] ; then
        # the following protects the rm -rf call (making sure that it is not null and really is a directory)
        if [ X$wdir != X ] ; then
            if [ -d $wdir ] ; then
                # should be safe to call here without trying to remove . or $HOME or /
                rm -rf $wdir
            fi
        fi
    fi

}

if (($# == 0)) || [[ "$1" == --* ]]
then
    #named parameters
    main "$@"
else
    #positional support goes here - just call main with named parameters built from $1, etc
    log_Err_Abort "positional parameter support is not currently implemented"
    main --workingDir="$1" --imageList="$2" --ref="$3" --refMask="$4" --out="$5" --brainSize="$6" --crop="$7" --clean="$8" --verbose="$9"
fi
