.PHONY: all clean

#URL_LIFESPANCN="https://pitt.box.com/shared/static/8uwfzmrztqia23o9k2tswzmyc8sutcj7.gz"
URL_ADNI="https://pitt.box.com/shared/static/9u5ztg9zku9etz8glwbdhw581l0plflh.gz"
URL_MODELS="https://pitt.box.com/shared/static/vufjnf7qbyk0mn15s5rwndn327vea25b.gz"

STUDY?=ADNI
DATA_RAW?=data/raw/$(STUDY)
PIPELINE?=RPP
DATA_PREPROCESSED?=data/preprocessed/$(STUDY)/$(PIPELINE)
SUBJECTS?=$(DATA_RAW)/ID_list.txt
SUBJECTS_PREPROCESSED?=$(DATA_PREPROCESSED)/logged_ID_list.txt
# Get filename without extension
SUBJECTS_BASENAME=$(basename $(SUBJECTS))
SUBJECTS_BASENAME:=$(notdir $(SUBJECTS_BASENAME))
B0?=3T
MODEL?=models/DBN_model.h5

DATA_PROCESSED=data/processed/$(STUDY)/$(PIPELINE)
BRAIN_AGES = $(DATA_PROCESSED)/brain_ages.txt

ifeq ($(STUDY), ADNI)
	URL_DATA=$(URL_ADNI)
	# change after transfer learning target to ADNI data
	URL_MODEL=$(URL_MODELS)
else
	URL_DATA=$(URL_LIFESPANCN)
	URL_MODEL=$(URL_MODELS)
endif

ifeq ($(PIPELINE), RPP)
	PREPROCESSING_SCRIPT=src/data/RPP/RPPBatch.sh
else
	# change to add other pipelines in the future
	PREPROCESSING_SCRIPT=src/data/RPP/RPPBatch.sh
endif

all: $(BRAIN_AGES)

clean:
	rm -rf $(DATA_PREPROCESSED)
	rm -rf $(DATA_PROCESSED)
	rm -rf logs/$(STUDY)/$(PIPELINE)

### GENERAL PIPELINE ###
# Rule for dowloading raw data
$(DATA_RAW):
	bash src/data/download.sh $(URL_DATA) $(DATA_RAW)

$(SUBJECTS): $(DATA_RAW)
	python src/data/create_subjects_list.py $(DATA_RAW) $@

# Rule for preprocessing raw data
$(DATA_PREPROCESSED): $(DATA_RAW)
	bash $(PREPROCESSING_SCRIPT) --studyFolder=$(DATA_RAW) --subjects=$(SUBJECTS) --b0=$(B0) --runLocal=no --linear=yes

$(SUBJECTS_PREPROCESSED): $(DATA_PREPROCESSED)
	python src/data/create_subjects_list.py $(DATA_PREPROCESSED) $@

# Rule for dowloading models
# Change to add specific links to specific models online
$(MODEL):
	bash src/models/models.sh  $(URL_MODEL) models

# Rule for predicting brain ages
$(BRAIN_AGES): $(DATA_PREPROCESSED) $(SUBJECTS_PREPROCESSED) $(MODEL)
	bash src/app/prediction.sh --data=$(DATA_PREPROCESSED) --filename=$@ --model=$(MODEL) --b0=$(B0) --out=$(DATA_PROCESSED) --linear=yes
