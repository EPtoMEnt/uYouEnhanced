#!/bin/bash
# To build, either place the IPA file in the project's root directory, or get the path to the IPA, then run `./build.sh`

set -e

# Resolve THEOS if not already set
if [ -z "$THEOS" ]; then
    if [ -d "$HOME/theos" ]; then
        export THEOS="$HOME/theos"
    elif [ -d "/opt/theos" ]; then
        export THEOS="/opt/theos"
    else
        echo "❌ Error: Theos not found. Set the THEOS environment variable or install Theos to ~/theos."
        exit 1
    fi
fi

# Ensure theos-jailed module is installed (required to produce an IPA instead of a .deb)
if [ ! -d "$THEOS/mod/jailed" ]; then
    echo "==> theos-jailed module not found. Installing..."
    JAILED_TMP="$(mktemp -d)"
    git clone --quiet https://github.com/qnblackcat/theos-jailed.git "$JAILED_TMP"
    (cd "$JAILED_TMP" && ./install)
    rm -rf "$JAILED_TMP"
    echo "==> theos-jailed installed successfully."
fi

read -p $'\e[34m==> \e[1;39mPath to the decrypted YouTube.ipa or YouTube.app. If nothing is provided, any ipa/app in the project\'s root directory will be used: ' PATHTOYT

# Check if PATHTOYT is empty
if [ -z "$PATHTOYT" ]; then
    # Look for ipa/app files in the current directory
    IPAS=$(find . -maxdepth 1 -type f \( -name "*.ipa" -o -name "*.app" \))

    # Check if there are two or more ipa/app files
    COUNT=$(echo "$IPAS" | wc -l)

    if [ "$COUNT" -ge 2 ]; then
        echo "❌ Error: Multiple IPA/app files found in the project's root directory. Make sure there is only one ipa."
        exit 1

    elif [ -n "$IPAS" ]; then
        PATHTOYT=$(echo "$IPAS" | head -n 1)

    else
        echo "❌ Error: No IPA/app file found in the project's root directory."
        exit 1
    fi
fi

make package THEOS_PACKAGE_SCHEME=rootless IPA="$PATHTOYT" FINALPACKAGE=1

# SHASUM
if [[ $? -eq 0 ]]; then
  open packages
  echo "SHASUM256: $(shasum -a 256 packages/*.ipa)"
else
  echo "Failed building uYouEnhanced"
fi
