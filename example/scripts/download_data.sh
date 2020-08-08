#! /bin/bash

set -e

URL_DATA=$1
DATA_PATH=$2

download_data() {
    curl -L -o example/data/raw/sample_T1.tar.gz $URL_DATA
    tar -xzf example/data/raw/sample_T1.tar.gz --strip-components 1 -C $DATA_PATH
    rm example/data/raw/sample_T1.tar.gz
}

main() {
    download_data
}

main
