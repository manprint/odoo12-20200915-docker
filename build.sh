#!/bin/bash

set -xev

echo "Script name: build odoo image"
echo "*****************************"

docker build --force-rm	--tag ghcr.io/manprint/odoo12-20200915:latest .

