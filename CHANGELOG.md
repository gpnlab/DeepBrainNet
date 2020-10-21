# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- src/data/RPP/data.py Manage the data folder

## [3.0.0] - 2020-10-20
### Added
-src/data/MPP/scripts/BiasCorrection.sh
-src/data/MPP/scripts/BiasCorrection.m
-src/data/MPP/scripts/BrainExtractionSegmentationBased.sh
-src/data/MPP/scripts/BrainExtractionSegmentationBased.m

### Changed

### Removed
-src/data/MPP/scripts/ACPCAlignment.sh
-src/data/MPP/scripts/OneStepResampledACPC.sh

### Fixed

## [2.0.0] - 2020-09-08
### Added
- src/data/RPP/RPP_workstation.sh
- src/data/RPP/runRPP_workstation.sh
- src/data/RPP/organize_HCP_unprocessed_data.sh Translate folder scheme from HCP to RPP style

### Changed
- src/data/RPP/runRPPCRC.sh -> src/data/RPP/runRPP_CRC.sh
- src/data/RPP/runRPPCluster.sh -> src/data/RPP/runRPP_Cluster.sh

### Removed

### Fixed
- src/data/RPP/RPP.sh Fix non-binary comparision
- src/data/rpp/rpp_crc.sh fix module loading in crc
- src/data/RPP/scripts/AnatomicalAverage.sh Fix image paths
- src/data/RPP/runRPP_CRC.sh Increase mem-per-cpu and time limit for job completion

## [1.3.0] - 2020-09-04
### Added
- .gitignore add /data/external to source control

### Changed
- src/data/RPP/RPPBatch.sh Add T2w processing capability
- src/data/RPP/RPPBatch.sh Replace `--studyFolder` by `--sutdyName`
- src/data/RPP/runRPPCluster.sh add the `--linear` flag
- src/data/RPP/scripts/* Add T2w processing capability

### Removed

### Fixed
- src/data/RPP/scripts/AnatomicalAverage.sh Replace imln with imcp
- src/data/RPP/scripts/AnatomicalAverage.sh Replace `cleanup` with `clean`

## [1.2.0] - 2020-09-01
### Added
- .cvsignore files and folders to be ignored by rsync
- src/data/RPP/RPPCluster.sh slurm submitting script
- src/data/RPP/runRPPCluster.sh slurm queueing script

### Changed
- src/data/RPP/RPP.sh save byproducts and results in a temporary folder
- src/data/RPP/RPPBatch.sh changed input parser to newer version

### Removed

### Fixed
- Makefile name of subjects file and input string of preprocessing script

## [1.1.0] - 2020-08-26
### Added
- src/data/RPP/scripts/AnatomicalAverage_old.sh for backwards compability
- src/data/RPP/scripts/AtlasRegistrationToMNI152FLIRT.sh linear atlas registration to MNI152
- src/data/get_preprocessed_subjects.sh create a list of logged subject IDs

### Changed
- Makefile add linear input parameter to scripts by default
- src/app/pred.py sort ID values
- src/data/create_subjects_list.py sort ID values
- src/app/prediction.sh add linear registration support
- src/app/RPP.sh add linear registration support
- src/app/RPPBatch.sh add linear registration support
- src/data/RPP/scripts/AnatomicalAverage.sh improved input parsing method
- src/data/RPP/scripts/AtlasRegistrationToMNI152FLIRTandFNIRT.sh explicity mention  nonlinear atlas registration
- src/models/download.sh rename and make download script general

### Removed

### Fixed
- src/app/prediction.sh fix setup path
- src/app/setUpApp.sh cleanup by calling src/global/config/setUpDBN.sh
- src/app/setUpRPP.sh global setup path is independent of calling script
- src/global/config/setUpDBN.sh DBNDIR path is independent of calling script

## [1.0.0] - 2020-08-17
### Added
- version.txt shows version
- product.txt shows tool name
- src/global/libs/newopts.shlib named parameter parsing code
- src/global/libs/log.shlib log to command line helpers
- src/global/config/setUpDBN.sh setup FSL and package paths
- src/data/create_subjects_list.py makes list of subjects in a given folder
- src/data/RPP Registration-based Preprocessing Pipeline
- src/app/prediction.sh predicts a brain age given a brain extracted, MNI registered T1w Image
- src/app/setUpApp.sh sets global variables for prediction.sh
- example/scripts/download_data.sh

### Changed
- src/data/donwload.sh is more general
- src/models/donwload_models.sh is more general
- README.md explains how to use the RPP
- src/app/pred.py clean dead code and change how to create IDList
- .gitignore now excludes logs from source control by default
- Makefile Added preprocessing using RPP into the pipeline

### Removed

### Fixed
- src/data/slicer.py fix "/" in data paths
- example/scripts/slicer.py fix "/" in data paths

## [0.0.1] - 2020-08-03
### Added
- app/pred.py applies model to data e return estimated brain age
- environment_without_dependencies.yml simple file with the depencies
- src/data/download.sh download the two T1 example nifti files
- src/data/slicer.py gets a nifti file and unwrap into .jpg for each slice
- src/models/download_example_model.sh downloads example model from box
- src/models/download_models.sh downloads models from box
- docs folder
- example folder that contains a small, standalone version

### Changed
- README.md explains how to create virtual environment, run the pipeline and example version. It also specifies the data requirements and show the results for each model for the two sample T1 nifti files
- environment.yml with complete dependencies specification
- CHANGELOG.md reflects version 0.0.1
- .gitignore now ignores example/data and example/models folders
- Makefile with the pipeline from download of data and models to prediciton. Also includes the pipeline for the example

### Removed
- Deleted reports folder; new format is results and docs folders

### Fixed

[Unreleased]:https://github.com/gpnlab/DeepBrainNet/compare/v2.0.0...HEAD
[3.0.0]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v3.0.0
[2.0.0]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v1.3.0
[1.3.0]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v1.2.0
[1.1.0]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v1.1.0
[1.0.0]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v1.0.0
[0.0.1]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v0.0.1
