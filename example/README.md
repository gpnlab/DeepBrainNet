# DeepBrainNet Example

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

## Running the Model

To run the example model either:

Execute `run_test.sh` inside the scripts folder to perform brain age prediction on T1 brain scans.
Or

The results can be found at both `example/results/DBN_model_pred.csv`

## Results

These are the values to expect when running the example model on the two sample T1 images made available

| Model      | Predicted Age    |
|------------|------------------|
| ID 3       | 77.0701065063477 |
| ID 4       | 75.2567977905273 |
