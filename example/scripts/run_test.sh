#! /bin/bash

set -e

URL_DATA='https://pitt.box.com/shared/static/8uwfzmrztqia23o9k2tswzmyc8sutcj7.gz'
URL_MODEL='https://pitt.box.com/shared/static/jwmwhr53nms1m4049i9q6ugawccx4hjn.gz'
OUTPUT_PATH='../results/pred.csv'

clean_example() {
	rm -f ../data/raw/*.nii.gz
	rm -f ../data/interim/Test/*
	rm -f ../results/*.csv
	rm -rf ../models/*
}

download_data() {
    curl -L -o ../data/raw/sample_T1.tar.gz $URL_DATA
    tar -xzf ../data/raw/sample_T1.tar.gz --strip-components 1 -C ../data/raw/
    rm ../data/raw/sample_T1.tar.gz
}

download_example_model() {
    curl -L -o ../models/DBN_model.tar.gz $URL_MODEL
    tar -xzf ../models/DBN_model.tar.gz --strip-components 1 -C ../models/
    rm ../models/DBN_model.tar.gz
}

main() {
    clean_example
    download_data
    download_example_model
    # Getting slices
    python slicer.py ../data/raw/ ../data/interim/Test/
    # Predicting age
    python pred.py "../data/interim/" "../models/DBN_model.h5" "$OUTPUT_PATH"
}

main
