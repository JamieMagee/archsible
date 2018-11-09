#!/usr/bin/env bash

echo "Adding commit hooks..."
shopt -s nullglob

# Directory containing this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

for hook in "$DIR"/hooks/*.hook; do
	hookname=${hook##*/}
	echo "-> ${hookname}"
	ln -sf "${hook}" "$(git rev-parse --git-dir)/hooks/${hookname%.hook}"
done
