#!/bin/bash
set -e

roles=$(find roles/ -maxdepth 2 -name 'molecule' -type d -printf '%h\n')

for role in $roles; do
    cd "$role"
    molecule test
    cd ../..
done