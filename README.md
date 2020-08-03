# DeepBrainNet

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
- Scans shoud be skull-striped and linearly registered

## Running the Models

go to the repository root folder and run
```bash
$ make
```
This will download the two sample T1 images and all the models made available if they weren't downloaded already. The models and sample data are currently served statically at my pitt.box.com. After downloanding is done, the default model, `DeepBrainNet_Normalized_General` is ran on the sample data. The result will be stored in the folder results under `DeepBrainNet_Normalized_General_pred.csv`.

To run the other models, on the repo root, run instead:
```bash
$ make MODEL=<model name>
```
For instance
```bash
$ make MODEL=DeepBrainNet_VGG16
```
List of available models:
1. DeepBrainNet_Densenet169
2. DeepBrainNet_InceptionResnetv2
3. DeepBrainNet_Normalized_General
4. DeepBrainNet_Normalized_General_2
5. DeepBrainNet_Normalized_General_3
6. DeepBrainNet_Resnet50
7. DeepBrainNet_VGG16

## The `example` folder

To run the example model either:

1. Execute `run_test.sh` inside the scripts folder to perform brain age prediction on T1 brain scans.
Or
2. run `make example` in the repo root folder:

The results can be found at both `example/results/DBN_model_pred.csv` and `results/DBN_model_pred.csv`

## Results

These are the values to expect when running the models on the two sample T1 images made available

### ID 3
| Model                    | Predicted Age    |
|--------------------------|------------------|
| DenseNet169              | 53.3524971008301 |
| InceptionResnetv2        | 55.6041603088379 |
| DBN Normalized General   | 50.4534072875977 |
| DBN Normalized General 2 | 60.6351318359375 |
| DBN Normalized General 3 | 51.4768524169922 |
| Resnet 50                | 55.8279495239258 |
| VGG16                    | 62.8666763305664 |
| Example DBN Model        | 77.0701065063477 |

### ID 4
| Model                    | Pred Age         |
|--------------------------|------------------|
| DenseNet169              | 51.0176010131836 |
| InceptionResnetv2        | 51.1781044006348 |
| DBN Normalized General   | 47.7161865234375 |
| DBN Normalized General 2 | 55.9849929809570 |
| DBN Normalized General 3 | 48.4056930541992 |
| Resnet 50                | 53.6797752380371 |
| VGG16                    | 60.1769561767578 |
| DBN                      | 60.1769561767578 |
| Example DBN Model        | 75.2567977905273 |
