# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]:https://github.com/gpnlab/DeepBrainNet/compare/v1.0.0...HEAD
[1.0.0]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v1.0.0
[0.0.1]:https://github.com/gpnlab/DeepBrainNet/releases/tag/v0.0.1
