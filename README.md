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
- For example, if using data from the ADNI dataset and running the MPP (Minimal Processing Pipeline), pipeline provided in this package, the preprocessed data will be stored in `data/preprocessed/ADNI/MPP`.

## MPP
As of version 1.0.0 the RPP is available.

As of version 1.1.0 it is also possible to perform RPP with linear registration, instead of nonlinear registration. This is now the default behavior since it conforms with the origional tranning dataset. to change this behavior see the help on function `src/data/RPP/RPP.sh`. Basically, you just need to pass the flag `--linear=no` to `RPP.sh`

As of version 2.0.0 there is support to processing both T1w and T2w images. It also supports simple anatomical average of repeated scans.

As of version 3.0.0 there are major changes. First, there is now support for segmentation-based brain extraction in additional to registration-based brain extraction, so the pipeline was renamed from Registration-based Processing Pipeline (RPP) to Minimal Processing Pipeline (MPP) to better reflect its capabilities.
Also, bias correction capability was added. Both segmentation-based brain extraction and bias correction requires MATLAB and SPM12. The so-called native space (align with ACPC line) and the one-step transform to native space were removed as it added unecessary processing that increase the processing time and the likelihood of resampling errors.
Finally, better naming conventions and folder organization for log files and output were implemented.

The primary purposes of the MPP are:

1. To average any image repeats (i.e. multiple T1w images available)
2. To perform bias correction
2. To provide an initial robust brain extraction
4. To register the subject's structural images to the MNI space

 ## Prerequisites:

 ### Installed Software

 * [FSL][FSL] - FMRIB's Software Library (version 5.0.6)
 * MATLAB
 * SPM12

 ### Environment Variables

 * MPPDIR

 * MPP_Scripts

   Location of MPP sub-scripts that are used to carry out some of steps of the MPP.

 * FSLDIR

   Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
   University

 * MATLABDIR

   Home directory for MATLAB from

 * SPM12DIR

   Home directory for SPM12 from

 ### Image Files

 At least one T1 weighted image and one T2 weighted image are required for this
 script to work.

 ### Output Directories

 Command line arguments are used to specify the studyName (--studyName) and
 the subject (--subject).  All outputs are generated within the tree rooted
 at ./studyName}/subject.  The main output directories are:

 * The t1wFolder: ./tmp/studyName/subject/b0/t1w
 * The t2wFolder: ./tmp/studyName/subject/b0/t2w
 * The MNIFolder: ./tmp/studyName/subject/b0/MNI

 All outputs are generated in directories at or below these two main
 output directories.  The full list of output directories is:

 * t1wFolder/AverageT1wImages
 * t1wFolder/BrainExtractionRegistration(Segmentation)Based
 * t1wFolder/xfms - transformation matrices and warp fields

 * t2wFolderAverageT1wImages
 * t2wFolder/BrainExtractionRegistration(Segmentation)Based
 * t2wFolder/xfms - transformation matrices and warp fields

 * MNIFolder
 * MNIFolder/xfms

 Logs are saved in `logs/MPP`

 ### Output Files

 * t1wFolder Contents: TODO
 * t2wFolder Contents: TODO
 * MNIFolder Contents: TODO

Note that no assumptions are made about the input paths with respect to the
output directories. All specification of input files is done via command
line arguments specified when this script is invoked.

Also note that the following output directories are created:

* `t1wFolder`, which is created by concatenating the following four option
values: `--studyFolder / --subject / --b0 / --t1`
* `t2wFolder`, which is created by concatenating the following four option
values: `--studyFolder / --subject / --b0 / --t2`


### Running MPP on a computer cluster
As of version 1.2.0, it is possible to submit MPP jobs to a cluster. More information by seeing the help `src/data/MPP/runMPP_Cluster.sh --help`. There you can find all the flags you can submit to slurm-managed clusters. The submitting script can be found in `src/data/MPP/MPP_Cluster.sh`.

As of version 1.3.0, it is also possible to submit MPP jobs to the H2P computational cluster at the Center for Research Computing (CRC). More information by seeing the help `src/data/MPP/runMPP_CRC.sh --help`. The submitting script can be found in `src/data/MPP/MPP_CRC.sh`. Remember to load python before calling the script with `module load python/anaconda3.7-5.2.0` as it requires `numpy`.

<!-- References -->
[FSL]: http://fsl.fmrib.ox.ac.uk

## Running the models

Go to the repository root folder and run
```bash
$ make
```
This will download the four ADNI sample T1 images and all the models made available if they weren't downloaded already. The models and sample data are currently served statically at my pitt.box.com.

After the download, the raw data (`data/raw/ADNI`) is preprocessed using the MPP and stored in `data/preprocessed/ADNI/MPP`.

Then the model `DBN_model.h5` is ran on the sample data. The result will be stored in the folder results under `data/processed/ADNI/MPP/subjects/brain_age.txt`.

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

These are the values to expect when running the models on the four ADNI samples using the MPP

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
