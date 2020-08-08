#! /bin/bash

set -e

URL_EXAMPLE_MODEL=$1
EXAMPLE_MODEL_PATH=$2

download_example_model() {
    curl -L -o example/models/DBN_model.tar.gz $URL_EXAMPLE_MODEL
    tar -xzf example/models/DBN_model.tar.gz --strip-components 1 -C $EXAMPLE_MODEL_PATH
    rm example/models/DBN_model.tar.gz
    cp example/models/DBN_model.h5 models/
}

main() {
    download_example_model
}

main
