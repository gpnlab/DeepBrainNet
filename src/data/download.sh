#! /bin/bash

set -e

URL_DATA=$1
DATA_PATH=$2
TMP="${DATA_PATH}/tmp"

download_data() {
    curl -L -o ${TMP}/data.tar.gz $URL_DATA
    tar -xzf ${TMP}/data.tar.gz --strip-components 1 -C $DATA_PATH
}

main() {
    mkdir -p $TMP
    download_data
    rm -r $TMP
}

main
