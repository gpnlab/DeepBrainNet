.PHONY: all example clean clean_example

URL_SAMPLE_DATA="https://pitt.box.com/shared/static/8uwfzmrztqia23o9k2tswzmyc8sutcj7.gz"
URL_RPP_ADNI_DATA="https://pitt.box.com/shared/static/h0k2mgo1opbnvqn0e3c2jzijttjp4t8w.gz"
URL_MODELS="https://pitt.box.com/shared/static/btqam5ompyci91rvrqnmcw3vtarmxnro.gz"
URL_EXAMPLE_MODELS="https://pitt.box.com/shared/static/jwmwhr53nms1m4049i9q6ugawccx4hjn.gz"

STUDY?=RPP/ADNI
DATA_DIR=data/interim/$(STUDY)
EXAMPLE_DATA_DIR=example/$(DATA_DIR)

ifeq ($(STUDY), RPP/ADNI)
	URL=$(URL_RPP_ADNI_DATA)
else
	URL=$(URL_SAMPLE_DATA)
endif

EXAMPLE_MODELS_FOLDER=example/models/
EXAMPLE_MODELS=DBN_model
EXAMPLE_MODELS_PATH=$(EXAMPLE_MODELS_FOLDER)$(EXAMPLE_MODELS).h5
EXAMPLE_OUT_FILE=example/results/$(EXAMPLE_MODELS)_pred.csv

MODELS_FOLDER=models/
MODEL?=DBN_model
MODEL_PATH=$(MODELS_FOLDER)$(MODEL).h5
OUT_FILE=results/$(STUDY)/$(MODEL)_pred.csv

all: $(OUT_FILE)

example: $(EXAMPLE_OUT_FILE)

clean:
	rm -rf $(DATA_DIR)
	rm -rf $(DATA_DIR)/Test
	rm -rf results/sample
#	rm -rf models/*.h5

clean_example:
	rm -rf $(EXAMPLE_DATA_DIR)
	rm -rf $(EXAMPLE_DATA_DIR)/Test
	rm -f  example/results/*
	rm -f  results/sample/DBN_model_pred.csv
	rm -rf example/models/*

### GENERAL PIPELINE ###
# Rules for dowloading raw sample T1 data
$(DATA_DIR)/:
	sh src/data/download.sh $(URL) $(DATA_DIR)
$(EXAMPLE_DATA_DIR)/:
	sh example/scripts/download_data.sh  $(URL) $(EXAMPLE_DATA_DIR)

# Rules for preprocessing data
$(DATA_DIR)/Test/: $(DATA_DIR)/
	mkdir -p $@
	python src/data/slicer.py $< $@
# Rule for preprocessing example data
$(EXAMPLE_DATA_DIR)/Test/: $(EXAMPLE_DATA_DIR)/
	mkdir -p $@
	python example/scripts/slicer.py $< $@

# Rule for dowloading models
$(MODEL_PATH):
	sh src/models/download_models.sh  $(URL_MODELS) $(MODELS_FOLDER)
# Rule for dowloading example DBN model
$(EXAMPLE_MODELS_PATH):
	sh example/scripts/download_model.sh $(URL_EXAMPLE_MODELS) $(EXAMPLE_MODELS_FOLDER)

# Rules for age prediction for models
$(OUT_FILE): $(DATA_DIR)/Test/ $(MODEL_PATH)
	mkdir -p results/$(STUDY)
	python src/app/pred.py $(DATA_DIR) $(MODEL_PATH) $@
# Rule for age prediction for example DBN models
$(EXAMPLE_OUT_FILE): $(EXAMPLE_DATA_DIR)/Test/ $(EXAMPLE_MODELS_PATH)
	python example/scripts/pred.py $(EXAMPLE_DATA_DIR) $(EXAMPLE_MODELS_PATH) $@
	mkdir -p results/sample
	cp $(EXAMPLE_OUT_FILE) results/sample/$(EXAMPLE_MODELS)_pred.csv
