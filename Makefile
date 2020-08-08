.PHONY: all example clean clean_example

URL_DATA="https://pitt.box.com/shared/static/8uwfzmrztqia23o9k2tswzmyc8sutcj7.gz"
URL_MODELS="https://pitt.box.com/shared/static/btqam5ompyci91rvrqnmcw3vtarmxnro.gz"
URL_EXAMPLE_MODELS="https://pitt.box.com/shared/static/jwmwhr53nms1m4049i9q6ugawccx4hjn.gz"

EXAMPLE_MODELS_FOLDER=example/models/
EXAMPLE_MODELS=DBN_model
EXAMPLE_MODELS_PATH=$(EXAMPLE_MODELS_FOLDER)$(EXAMPLE_MODELS).h5
EXAMPLE_OUT_FILE=example/results/$(EXAMPLE_MODELS)_pred.csv

MODELS_FOLDER=models/
MODEL?=DeepBrainNet_Normalized_General
MODEL_PATH=$(MODELS_FOLDER)$(MODEL).h5
OUT_FILE=results/$(MODEL)_pred.csv

all: $(OUT_FILE)

example: $(EXAMPLE_OUT_FILE)

clean:
	rm -f data/raw/*.nii.gz
	rm -f data/interim/Test/*
	rm -f results/*.csv
	rm -rf models/*.h5

clean_example:
	rm -f example/data/raw/*.nii.gz
	rm -f example/data/interim/Test/*
	rm -f example/results/*.csv
	rm -rf example/models/*

### GENERAL PIPELINE ###
# Rules for dowloading raw T1 data
data/raw/T1_3.nii.gz:
	sh src/data/download.sh $(URL_DATA) data/raw/
example/data/raw/T1_3.nii.gz:
	sh example/scripts/download_data.sh  $(URL_DATA) example/data/raw/

# Rules for preprocessing data
data/interim/Test/T1_3-0.jpg: data/raw/T1_3.nii.gz
	python src/data/slicer.py data/raw/ data/interim/Test/
# Rule for preprocessing example data
example/data/interim/Test/T1_3-0.jpg: example/data/raw/T1_3.nii.gz
	python example/scripts/slicer.py example/data/raw/ example/data/interim/Test/

# Rule for dowloading models
$(MODEL_PATH):
	sh src/models/download_models.sh  $(URL_MODELS) $(MODELS_FOLDER)
# Rule for dowloading example DBN model
$(EXAMPLE_MODELS_PATH):
	sh example/scripts/download_model.sh $(URL_EXAMPLE_MODELS) $(EXAMPLE_MODELS_FOLDER)

# Rules for age prediction for models
$(OUT_FILE): data/interim/Test/T1_3-0.jpg $(MODEL_PATH)
	python src/app/pred.py data/interim/ $(MODEL_PATH) $@
# Rule for age prediction for example DBN models
$(EXAMPLE_OUT_FILE): example/data/interim/Test/T1_3-0.jpg $(EXAMPLE_MODELS_PATH)
	python example/scripts/pred.py example/data/interim/ $(EXAMPLE_MODELS_PATH) $@
	cp $(EXAMPLE_OUT_FILE) results/$(EXAMPLE_MODELS)_pred.csv
