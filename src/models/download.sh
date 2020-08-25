#! /bin/bash

set -e

URL_MODELS=$1
MODELS_PATH=$2
TMP="${MODELS_PATH}/tmp"

download_models() {
    curl -L -o ${TMP}/models.tar.gz $URL_MODELS
    tar -xzf ${TMP}/models.tar.gz --strip-components 1 -C $MODELS_PATH
}

main() {
    mkdir -p $TMP
    download_models
    rm -r $TMP
}

main
