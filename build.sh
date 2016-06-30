#!/bin/bash

# Do a Packer build
echo "Building via Packer"
PACKER_LOG=1 /usr/local/bin/packer build ./packer/template.json
