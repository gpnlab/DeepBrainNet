.PHONY: all example clean clean_example

URL_LIFESPANCN="https://pitt.box.com/shared/static/8uwfzmrztqia23o9k2tswzmyc8sutcj7.gz"
URL_ADNI="https://pitt.box.com/shared/static/h0k2mgo1opbnvqn0e3c2jzijttjp4t8w.gz"
URL_MODELS="https://pitt.box.com/shared/static/btqam5ompyci91rvrqnmcw3vtarmxnro.gz"
URL_DBN_MODEL="https://pitt.box.com/shared/static/jwmwhr53nms1m4049i9q6ugawccx4hjn.gz"

STUDY?=ADNI
DATA_RAW?=data/raw/$(STUDY)
PIPELINE?=RPP
DATA_PREPROCESSED?=data/preprocessed/$(STUDY)/$(PIPELINE)
SUBJECTS?=$(DATA_RAW)/subjects.txt
SUBJECTS_PREPROCESSED?=$(DATA_PREPROCESSED)/subjects.txt
# Get filename without extension
SUBJECTS_BASENAME=$(basename $(SUBJECTS))
SUBJECTS_BASENAME:=$(notdir $(SUBJECTS_BASENAME))
B0?=3T
MODEL?=models/DBN_model.h5
OUTPUT_DIR=$(DATA_PREPROCESSED)/$(SUBJECTS_BASENAME)
OUTPUT_FILE = $(OUTPUT_DIR)/brain_ages.txt

ifeq ($(STUDY), ADNI)
	URL_DATA=$(URL_ADNI)
	# change after transfer learning ADNI data
	URL_MODEL=$(URL_DBN_MODEL)
else
	URL_DATA=$(URL_LIFESPANCN)
	URL_MODEL=$(URL_DBN_MODEL)
endif

ifeq ($(PIPELINE), RPP)
	PREPROCESSING_SCRIPT=src/data/RPP/RPPBatch.sh
else
	# change to add other pipelines in the future
	PREPROCESSING_SCRIPT=src/data/RPPBatch.sh
endif

all: $(OUTPUT_FILE)

clean:
	rm -rf $(OUTPUT_DIR)
	rm -f $(SUBJECTS_PREPROCESSED)

### GENERAL PIPELINE ###
# Rule for dowloading raw data
$(DATA_RAW):
	bash src/data/download.sh $(URL_DATA) $(DATA_RAW)

$(SUBJECTS): $(DATA_RAW)
	python src/data/create_subjects_list.py $(DATA_RAW) $@

# Rule for preprocessing raw data
$(DATA_PREPROCESSED): $(DATA_RAW)
	bash $(PREPROCESSING_SCRIPT) --studyFolder=$(DATA_RAW) --subjects=$(SUBJECTS) --b0=$(B0) --runLocal

$(SUBJECTS_PREPROCESSED): $(DATA_PREPROCESSED)
	python src/data/create_subjects_list.py $(DATA_RAW) $@

# Rule for dowloading models
# Change to add specific links to specific models online
$(MODEL):
	bash src/models/download_models.sh  $(URL_MODEL) models

# Rule for predicting brain ages
$(OUTPUT_FILE): $(DATA_PREPROCESSED) $(SUBJECTS_PREPROCESSED) $(MODEL)
	bash src/app/prediction.sh --data=$(DATA_PREPROCESSED) --subjects=$(SUBJECTS_PREPROCESSED) --model=$(MODEL) --b0=$(B0) --output=$@

