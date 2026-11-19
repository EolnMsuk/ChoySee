#!/bin/sh
set -eu

# Use modern Xcode and a RootHide Theos checkout (which also supports the
# default and rootless schemes), with matching AltList development frameworks.
: "${THEOS:?Set THEOS to the prepared RootHide Theos checkout}"

CDPATH= cd -P "$(dirname "$0")"
mkdir -p packages
release_scratch=$(mktemp -d "$PWD/packages/.release.XXXXXXXX")
trap 'rm -rf "$release_scratch"' 0
trap 'exit 1' HUP INT TERM

for scheme in rootless roothide ''; do
	profile=${scheme:-rootful}
	package_dir="$release_scratch/$profile"
	make clean FINALPACKAGE=1 CHOICY_LEGACY=0 THEOS_PACKAGE_SCHEME="$scheme"
	mkdir -p "$package_dir"
	make package FINALPACKAGE=1 CHOICY_LEGACY=0 THEOS_PACKAGE_SCHEME="$scheme" THEOS_PACKAGE_DIR="$package_dir"
	python3 .github/scripts/verify-package.py --label "$profile" --package-dir "$package_dir"
done
