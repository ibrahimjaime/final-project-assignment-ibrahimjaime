#!/bin/sh
# One-time setup: clones poky + meta-raspberrypi if not already present
# alongside this repo, initializes a build directory, and copies in this
# repo's local.conf/bblayers.conf templates as a starting point.
#
# Safe to skip entirely if you already have a working poky checkout and
# build directory from earlier course assignments — in that case just add
# meta-data-logger's path to your existing bblayers.conf by hand instead
# of running this script.

set -e

YOCTO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$YOCTO_ROOT"

if [ ! -d poky ]; then
    echo "Cloning poky..."
    git clone git://git.yoctoproject.org/poky
fi

if [ ! -d poky/meta-raspberrypi ]; then
    echo "Cloning meta-raspberrypi..."
    git clone git://git.yoctoproject.org/meta-raspberrypi poky/meta-raspberrypi
fi

cd poky
# shellcheck disable=SC1091
source oe-init-build-env build

echo "Copying config templates into build/conf/ (back up first if these already exist and you've customized them)..."
cp "$YOCTO_ROOT/yocto-data-logger-platform/build-templates/local.conf.sample" conf/local.conf.data-logger-additions
cp "$YOCTO_ROOT/yocto-data-logger-platform/build-templates/bblayers.conf.sample" conf/bblayers.conf.sample

cat <<'EOF'

Next steps (manual, since these files may already contain your own settings):
  1. Review conf/local.conf.data-logger-additions and merge the relevant
     lines into your real conf/local.conf.
  2. Review conf/bblayers.conf.sample and merge the meta-data-logger path
     into your real conf/bblayers.conf (update the absolute paths first).
  3. bitbake core-image-data-logger
     (or: bitbake data-logger   -- to build just the app package)
EOF
