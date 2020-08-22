#! /bin/bash

set -e

URL_EXAMPLE_MODEL=$1
MODELS_PATH=$2

download_models() {
    curl -L -o models/models.tar.gz $URL_EXAMPLE_MODEL
    tar -xzf models/models.tar.gz --strip-components 1 -C $MODELS_PATH
    rm models/models.tar.gz
}

main() {
    download_models
}

main
