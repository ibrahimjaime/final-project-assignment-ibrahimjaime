#!/bin/bash
# Automated build script for the Data Logging System Yocto image.
# Safe to run on a brand new machine right after cloning this repo: it
# fetches submodules, sets up the build directory, wires in the required
# layers, and builds the final image — all idempotently, so re-running it
# on a machine that's already partially set up just skips what's done.
 
set -e
 
# Resolve the repo root from this script's own location, so `build.sh`
# works correctly no matter what directory you invoke it from (unlike
# relying on the caller's current working directory).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"
 
POKY_DIR="$REPO_ROOT/poky"
BUILD_DIR="$POKY_DIR/build"
META_RASPBERRYPI_DIR="$REPO_ROOT/meta-raspberrypi"
META_DATA_LOGGER_DIR="$REPO_ROOT/meta-data-logger"
IMAGE_NAME="core-image-data-logger"
 
echo "Syncing and updating submodules..."
git submodule sync --recursive
git submodule update --init --recursive
 
if [ ! -f "$POKY_DIR/oe-init-build-env" ]; then
    echo "ERROR: $POKY_DIR/oe-init-build-env not found."
    echo "The poky submodule did not populate correctly — check 'git submodule status' above for errors."
    exit 1
fi
 
# --- Initialize (or re-enter) the build directory. Passing BUILD_DIR
# explicitly, rather than relying on the current working directory,
# guarantees the build always lands at poky/build regardless of where
# this script is invoked from. This also means conf/local.conf and
# conf/bblayers.conf are created fresh here on a first run. ---
echo "Initializing Yocto build environment at $BUILD_DIR..."
# shellcheck disable=SC1091
source "$POKY_DIR/oe-init-build-env" "$BUILD_DIR"
 
LOCAL_CONF="$BUILD_DIR/conf/local.conf"
BBLAYERS_CONF="$BUILD_DIR/conf/bblayers.conf"
 
# --- MACHINE ---
CONFLINE='MACHINE = "raspberrypi4-64"'
if ! grep -Fxq "$CONFLINE" "$LOCAL_CONF"; then
    echo "Adding $CONFLINE to local.conf"
    echo "$CONFLINE" >> "$LOCAL_CONF"
else
    echo "$CONFLINE already exists in local.conf"
fi
 
# --- UART ---
CONFLINE='ENABLE_UART = "1"'
if ! grep -Fxq "$CONFLINE" "$LOCAL_CONF"; then
    echo "Adding $CONFLINE to local.conf"
    echo "$CONFLINE" >> "$LOCAL_CONF"
else
    echo "$CONFLINE already exists in local.conf"
fi
 
# --- Layers: use absolute paths (computed from REPO_ROOT above) rather
# than relative paths like ../../meta-raspberrypi. Relative paths break
# the moment this script is run from a different working directory or
# the build dir's nesting ever changes; absolute paths don't care. ---
if ! bitbake-layers show-layers | grep -q "meta-raspberrypi"; then
    echo "Adding meta-raspberrypi layer"
    bitbake-layers add-layer "$META_RASPBERRYPI_DIR"
else
    echo "meta-raspberrypi layer already exists"
fi
 
if ! bitbake-layers show-layers | grep -q "meta-data-logger"; then
    echo "Adding meta-data-logger layer"
    bitbake-layers add-layer "$META_DATA_LOGGER_DIR"
else
    echo "meta-data-logger layer already exists"
fi
 
# --- Build ---
echo "Building $IMAGE_NAME (this can take a long time on a first/from-scratch run)..."
bitbake "$IMAGE_NAME"
 
DEPLOY_DIR="$BUILD_DIR/tmp/deploy/images/raspberrypi4-64"
echo ""
echo "Build complete. Flashable image(s):"
ls -la "$DEPLOY_DIR"/*.wic.bz2 2>/dev/null || echo "  (no .wic.bz2 found — check the build output above for errors)"