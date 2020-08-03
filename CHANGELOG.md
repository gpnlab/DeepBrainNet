# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]:
[0.0.1]:
