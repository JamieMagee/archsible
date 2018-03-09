#!/bin/bash
set -e

roles=$(find roles/ -maxdepth 4 -name 'Dockerfile.j2' -type f -printf '%h\n' | cut -d "/" -f1,2)

for role in $roles; do
    cd "$role"
    molecule test
    cd ../..
done