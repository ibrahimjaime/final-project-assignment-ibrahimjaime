#!/bin/bash
# Cleanup script for the Data Logging System Yocto build.
#
# Default (no flags): cleans the data-logger recipe's sstate/work output
# (bitbake -c cleansstate) AND, if you're using the EXTERNALSRC local-dev
# override, runs `make clean` in your local app checkout too — this is
# exactly the combination that would have caught the stale-native-binary
# bug we hit earlier (a leftover x86-64 build from a native `make` test
# silently getting copied into an aarch64 package because timestamps
# looked up to date).
#
# Usage:
#   ./clean.sh              # sstate-clean the recipe + clean local app checkout if applicable
#   ./clean.sh --sstate     # only the sstate/work clean
#   ./clean.sh --app        # only the local app checkout clean
#   ./clean.sh --full       # also wipe tmp/, sstate-cache/, cache/ for a true from-scratch rebuild
#   ./clean.sh --help

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

POKY_DIR="$REPO_ROOT/poky"
BUILD_DIR="$POKY_DIR/build"
RECIPE_NAME="data-logger"

DO_SSTATE=0
DO_APP=0
DO_FULL=0

if [ "$#" -eq 0 ]; then
    DO_SSTATE=1
    DO_APP=1
fi

for arg in "$@"; do
    case "$arg" in
        --sstate) DO_SSTATE=1 ;;
        --app)    DO_APP=1 ;;
        --full)   DO_FULL=1 ;;
        --help|-h)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (use --help for usage)"
            exit 1
            ;;
    esac
done

if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory at $BUILD_DIR — nothing to clean. Run build.sh first."
    exit 0
fi

# shellcheck disable=SC1091
source "$POKY_DIR/oe-init-build-env" "$BUILD_DIR" > /dev/null

if [ "$DO_SSTATE" -eq 1 ]; then
    echo "Cleaning sstate/work output for $RECIPE_NAME..."
    bitbake -c cleansstate "$RECIPE_NAME"
fi

if [ "$DO_APP" -eq 1 ]; then
    # Ask bitbake for the recipe's actual source directory rather than
    # assuming or hardcoding a path — this works whether you're on the
    # default git-fetch SRC_URI (S is inside tmp/work, already handled by
    # cleansstate above) or using an EXTERNALSRC override pointing at your
    # own checkout (in which case S is your real working tree, and only
    # `make clean` there — not cleansstate — actually removes its .o/binary).
    RECIPE_S="$(bitbake -e "$RECIPE_NAME" 2>/dev/null | grep -m1 '^S=' | cut -d'"' -f2)"

    if [ -n "$RECIPE_S" ] && [ -d "$RECIPE_S" ] && [ -f "$RECIPE_S/Makefile" ]; then
        case "$RECIPE_S" in
            "$BUILD_DIR"/tmp/work/*)
                echo "Recipe source is bitbake's own fetched copy under tmp/work — already handled by --sstate, skipping."
                ;;
            *)
                echo "Detected local EXTERNALSRC checkout at $RECIPE_S — running 'make clean' there."
                make -C "$RECIPE_S" clean
                ;;
        esac
    else
        echo "Could not resolve a local Makefile for $RECIPE_NAME's source dir — skipping app clean."
    fi
fi

if [ "$DO_FULL" -eq 1 ]; then
    echo "Removing tmp/, sstate-cache/, and cache/ under $BUILD_DIR for a full from-scratch rebuild..."
    rm -rf "$BUILD_DIR/tmp" "$BUILD_DIR/sstate-cache" "$BUILD_DIR/cache"
    echo "Done. Next build.sh run will re-fetch/re-build everything, including base Yocto layers — expect a long build."
fi

echo "Clean complete."
