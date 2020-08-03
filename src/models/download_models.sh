#! /bin/bash

set -e

URL_EXAMPLE_MODEL=$1
EXAMPLE_MODEL_PATH=$2

download_models() {
    curl -L -o models/DBN_models.tar.gz $URL_EXAMPLE_MODEL
    tar -xzf models/DBN_models.tar.gz --strip-components 1 -C $EXAMPLE_MODEL_PATH
    rm models/DBN_models.tar.gz
}

main() {
    download_models
}

main
