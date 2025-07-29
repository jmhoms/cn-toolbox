#!/bin/bash

# A script to safely update the Cardano P2P configuration.
# 1. Backs up the existing custom config.
# 2. Copies a fresh template config.
# 3. Applies custom P2P peer values using jq.

# --- Configuration ---

# 1) Define source and destination files
SOURCE_FILE="/opt/cardano/cnode/files/config.json"
DEST_FILE="/opt/cardano/cnode/files-custom/config.json"

# Define the desired P2P peer values
TARGET_ACTIVE=60
TARGET_ESTABLISHED=140
TARGET_KNOWN=250
TARGET_ROOT=120

# --- Pre-flight Checks ---

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it to run this script."
    echo "  (e.g., sudo apt update && sudo apt install jq)"
    exit 1
fi

# Check if the source config file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source configuration file '$SOURCE_FILE' not found."
    exit 1
fi

# --- Execution ---

echo "Starting configuration update process..."

# 2) First action: Backup the existing destination file if it exists
if [ -f "$DEST_FILE" ]; then
    echo "1. Backing up existing custom config to '${DEST_FILE}.bak'..."
    # The `cp` command will overwrite the .bak file if it already exists.
    cp "$DEST_FILE" "${DEST_FILE}.bak"
else
    echo "1. No existing '$DEST_FILE' to back up. Skipping."
fi

# 3) Second action: Copy a fresh template from source to destination
echo "2. Copying fresh config from source to '$DEST_FILE'..."
# Ensure the destination directory exists before copying
DEST_DIR=$(dirname "$DEST_FILE")
if [ ! -d "$DEST_DIR" ]; then
    echo "   Creating destination directory '$DEST_DIR'..."
    mkdir -p "$DEST_DIR"
fi
cp "$SOURCE_FILE" "$DEST_FILE"

# 4) Third action: Proceed with the substitution of values using jq
echo "3. Applying custom P2P peer values to '$DEST_FILE'..."
echo "   - TargetNumberOfActivePeers: $TARGET_ACTIVE"
echo "   - TargetNumberOfEstablishedPeers: $TARGET_ESTABLISHED"
echo "   - TargetNumberOfKnownPeers: $TARGET_KNOWN"
echo "   - TargetNumberOfRootPeers: $TARGET_ROOT"

# Use jq to update the values. This reads the destination file, applies changes,
# and writes the output to a temporary file for safety.
jq \
  --argjson active "$TARGET_ACTIVE" \
  --argjson established "$TARGET_ESTABLISHED" \
  --argjson known "$TARGET_KNOWN" \
  --argjson root "$TARGET_ROOT" \
  '
    .TargetNumberOfActivePeers = $active |
    .TargetNumberOfEstablishedPeers = $established |
    .TargetNumberOfKnownPeers = $known |
    .TargetNumberOfRootPeers = $root
  ' "$DEST_FILE" > "${DEST_FILE}.tmp"

# Check if jq command was successful before replacing the file
if [ $? -eq 0 ]; then
    # Move the temporary file to replace the original, completing the update.
    mv "${DEST_FILE}.tmp" "$DEST_FILE"
    echo "Update successful. '$DEST_FILE' is ready."
else
    echo "Error: jq command failed. The file '$DEST_FILE' might be incorrect."
    # Clean up the temporary file on failure
    rm -f "${DEST_FILE}.tmp"
    exit 1
fi

exit 0
