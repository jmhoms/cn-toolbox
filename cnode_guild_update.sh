#!/bin/bash

# This script downloads the Guild Operators deployment script to a specified
# temporary folder and extracts the version of 'cardano-node' it will install.

# --- Configuration ---
GUILD_SCRIPT_URL="https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/guild-deploy.sh"
GUILD_SCRIPT_NAME="guild-deploy.sh"

# 1) Set the custom temporary folder. By default, this is "$HOME/tmp".
# This directory will be created if it does not exist and will NOT be deleted by the script.
TMP_DIR="$HOME/tmp"

# --- Pre-flight Checks ---

# Check if curl is installed, as it's needed for the download
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is not installed. Please install it to run this script."
    echo "  (e.g., sudo apt update && sudo apt install curl)"
    exit 1
fi

# Exit immediately if any subsequent command fails.
set -e

# --- Setup ---
echo "Using directory for download: $TMP_DIR"
# Create the directory if it doesn't exist. '-p' prevents errors if it's already there
# and creates parent directories if needed.
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# --- Main Logic ---

echo "Downloading the Guild deployment script to '$PWD'..."
# -sS: Silent mode but show errors. -o: Output to file.
curl -sS -o "$GUILD_SCRIPT_NAME" "$GUILD_SCRIPT_URL"

# Check if the download was successful
if [ ! -f "$GUILD_SCRIPT_NAME" ]; then
    echo "Error: Failed to download the deployment script. Please check the URL and your connection."
    exit 1
fi

echo "Download complete. Analyzing script to find cardano-node version..."

# The guild-deploy.sh script defines the cardano-node version in a variable like:
# CN_VERSION="8.9.2"
# We will use text processing tools to find and isolate this value.

# grep: Find the line that starts with 'CN_VERSION='
# cut:  Split the line by the '=' delimiter and take the second part (the value)
# tr:   Delete any double-quote characters from the result
EXTRACTED_VERSION=$(grep '^CN_VERSION=' "$GUILD_SCRIPT_NAME" | cut -d'=' -f2 | tr -d '"')

# --- Output ---

if [ -n "$EXTRACTED_VERSION" ]; then
    echo "------------------------------------------------------------------"
    echo "Success! The version found in the script is:"
    echo "cardano-node version: $EXTRACTED_VERSION"
    echo "------------------------------------------------------------------"
    echo "The deployment script has been saved as: $TMP_DIR/$GUILD_SCRIPT_NAME"
else
    echo "Error: Could not find the CN_VERSION variable in the downloaded script."
    echo "The script's format may have changed."
    exit 1
fi

exit 0
