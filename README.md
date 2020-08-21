# DeepBrainNet
As seen in [here](https://academic.oup.com/brain/article-abstract/143/7/2312/5863667?redirectedFrom=fulltext)

Support data available in [here](https://github.com/vishnubashyam/DeepBrainNet)
## Dependency List

All dependencies are in the `environment.yml` file. You can create a `conda` environment named `DBN` and activate it with:
```bash
$ conda env create -f environment.yml -n DBN python
$ conda activate DBN
```
To update your environment, add/remove packages from `environment.yml` file and run:
```bash
$ conda env update -n DBN -f environment.yml --prune
```
To deactivate your environemnt, just run:
```bash
$ conda deactivate
```

## Data Requirements

- T1 scans must be in nifti format
- Scans can either be raw and placed on the `data/raw/<study name>`
- Or scans shoud be skull-striped and (linearly) registered and placed on the `data/preprocessed/<study name>/<pipeline>`, where `<pipeline>` is refers to which preprocessing pipeline was used.
- For example, if using data from the ADNI dataset and running the RPP (Registration-based Processing Pipeline), pipeline provided in this package, the preprocessed data will be stored in `data/preprocessed/ADNI/RPP`.

## RPP
The primary purposes of the RPP are:

1. To average any image repeats (i.e. multiple T1w images available)
2. To provide an initial robust brain extraction
3. To register the subject's native space to the MNI space

## Prerequisites:

### Installed Software

* [FSL][FSL] - FMRIB's Software Library (version >= 5.0.6)

### Environment Variables

* RPPDIR

* RPP_Scripts

Location of RPP sub-scripts that are used to carry out some of steps of the RPP.

* FSLDIR

Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
University

### Image Files

At least one T1 weighted image is required for this script to work.

### Output Directories

All outputs are generated within the tree rooted
at `${studyFolder}/${subject}`.  The main output directories are:

* The t1wFolder: `${DBNDir}/data/interim/${studyFolder}/${subject}/{b0}/t1w`
* The atlasSpaceFolder: `${studyFolder}/${subject}/${b0}/MNINonLinear`

All outputs are generated in directories at or below these two main
output directories.  The full list of output directories is:

* `${t1wFolder}/AverageT1wImages`
* `${t1wFolder}/ACPCAlignment`
* `${t1wFolder}/BrainExtractionFNIRTbased`
* `${t1wFolder}/xfms` - transformation matrices and warp fields

* `${atlasSpaceFolder}`
* `${atlasSpaceFolder}/xfms`

Note that no assumptions are made about the input paths with respect to the
output directories. All specification of input files is done via command
line arguments specified when this script is invoked.

Also note that the following output directory is created:

* `t1wFolder`, which is created by concatenating the following four option
values: `--studyFolder / --subject / --b0 / --t1`

Logs are saved in `logs/RPP`

<!-- References -->
[FSL]: http://fsl.fmrib.ox.ac.uk

## Running the models

Go to the repository root folder and run
```bash
$ make
```
This will download the four ADNI sample T1 images and all the models made available if they weren't downloaded already. The models and sample data are currently served statically at my pitt.box.com.

After the download, the raw data (`data/raw/ADNI`) is preprocessed using the RPP and stored in `data/preprocessed/ADNI/RPP`.

Then the model `DBN_model.h5` is ran on the sample data. The result will be stored in the folder results under `data/processed/ADNI/RPP/subjects/brain_age.txt`.

To run the other models, on the repo root, run instead:
```bash
$ make MODEL=<model name>
```
For instance
```bash
$ make MODEL=DeepBrainNet_VGG16
```
List of available models:
1. DBN_model
2. DeepBrainNet_Densenet169
3. DeepBrainNet_InceptionResnetv2
4. DeepBrainNet_Normalized_General
5. DeepBrainNet_Normalized_General_2
6. DeepBrainNet_Normalized_General_3
7. DeepBrainNet_Resnet50
8. DeepBrainNet_VGG16

## Results

These are the values to expect when running the models on the four ADNI samples using the RPP

### 002_S_0413
| Model                    | Predicted Age      |
|--------------------------|--------------------|
| DBN Model                | 57.97934341430664  |

### 002_S_0559
| Model                    | Pred Age           |
|--------------------------|--------------------|
| DBN Model                | 65.85028076171875  |

### 006_S_6234
| Model                    | Predicted Age      |
|--------------------------|--------------------|
| DBN Model                | 61.706581115722656 |

### 023_S_4448
| Model                    | Pred Age           |
|--------------------------|--------------------|
| DBN Model                | 48.529300689697266 |
