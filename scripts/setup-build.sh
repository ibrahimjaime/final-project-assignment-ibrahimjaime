#!/bin/sh
# One-time setup on a new machine: adds poky + meta-raspberrypi as git
# submodules pinned to the kirkstone branch (matching .gitmodules), then
# initializes a build directory and copies in this repo's local.conf /
# bblayers.conf templates as a starting point.
#
# If poky/meta-raspberrypi are ALREADY registered submodules (i.e.
# .gitmodules already has them and someone already ran `git submodule add`
# once), just run `git submodule update --init --recursive` instead of
# this whole script.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -d poky ] || [ -z "$(ls -A poky 2>/dev/null)" ] || [ ! -d meta-raspberrypi ] || [ -z "$(ls -A meta-raspberrypi 2>/dev/null)" ]; then
    if grep -q '\[submodule "poky"\]' .gitmodules 2>/dev/null && grep -q '\[submodule "meta-raspberrypi"\]' .gitmodules 2>/dev/null; then
        echo "poky and meta-raspberrypi are registered in .gitmodules — fetching pinned submodules..."
        git submodule update --init --recursive
    else
        echo "Registering poky as a submodule on kirkstone..."
        git submodule add -b kirkstone https://git.yoctoproject.org/poky poky
        # meta-raspberrypi must be a SIBLING of poky, not nested inside it —
        # git refuses to nest a second submodule's .git metadata inside
        # poky's own working tree once poky itself is a submodule.
        echo "Registering meta-raspberrypi as a submodule on kirkstone (sibling of poky)..."
        git submodule add -b kirkstone https://git.yoctoproject.org/meta-raspberrypi meta-raspberrypi
        git commit -m "Add poky and meta-raspberrypi as kirkstone submodules"
    fi
else
    echo "poky/ and meta-raspberrypi/ already present — run 'git submodule update --init --recursive' if either looks stale."
fi

cd poky
# shellcheck disable=SC1091
source oe-init-build-env build

echo "Copying config templates into build/conf/ (back up first if these already exist and you've customized them)..."
cp "$REPO_ROOT/build-templates/local.conf.sample" conf/local.conf.data-logger-additions
cp "$REPO_ROOT/build-templates/bblayers.conf.sample" conf/bblayers.conf.sample

cat <<'EOF'

Next steps (manual, since these files may already contain your own settings):
  1. Review conf/local.conf.data-logger-additions and merge the relevant
     lines into your real conf/local.conf.
  2. Review conf/bblayers.conf.sample and merge the meta-data-logger path
     into your real conf/bblayers.conf (update the absolute paths first).
  3. bitbake core-image-data-logger
     (or: bitbake data-logger   -- to build just the app package)
EOF
