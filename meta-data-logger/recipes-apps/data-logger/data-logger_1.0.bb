SUMMARY = "Data Logging System daemon"
DESCRIPTION = "USB telemetry ingestion daemon for the Raspberry Pi 4: reads \
attitude/speed/position JSON over USB via termios, buffers in RAM, and \
persists to SQLite in batched transactions, with an IPC-driven \
start/stop/restart state machine."
HOMEPAGE = "https://github.com/ibrahimjaime/final-project-assignment-apps-ibrahimjaime"

# CLOSED avoids requiring LIC_FILES_CHKSUM. If the app repo carries its own
# LICENSE file (e.g. MIT), switch this to the matching SPDX identifier and
# add LIC_FILES_CHKSUM pointing at that file's checksum instead.
LICENSE = "CLOSED"

# --- Default: fetch from the app repo (the reproducible, "anyone can build
# this" path). `?=` makes this a weak default so it can still be overridden
# entirely if ever needed, though the normal way to develop against a local
# working copy is EXTERNALSRC below, not overriding SRC_URI directly. Pin
# SRCREV to a real commit once Sprint 1 stabilizes instead of AUTOREV. ---
# SRC_URI ?= "git://github.com/ibrahimjaime/final-project-assignment-apps-ibrahimjaime.git;protocol=https;branch=master"

# PV = "1.0"
# S = "${WORKDIR}/git"

# SRCREV ?= "a1f5d5caf0b1b44441c49cafa505a06a712bd1cf"

# --- Local development option: compile directly from your own working
# copy of the app repo instead of fetching from git. This is deliberately
# NOT configured here, since it requires a machine-specific absolute path
# that must never be committed to this layer. Instead, set it in your own
# poky/build/conf/local.conf (a generated, machine-local file that is not
# part of this repo's git history):
#
INHERIT += "externalsrc"
EXTERNALSRC:pn-data-logger = "/home/ibrahim/Documents/course/final-project-assignment-apps"
EXTERNALSRC_BUILD:pn-data-logger = "/home/ibrahim/Documents/course/final-project-assignment-apps"
#
# With that override in place, do_fetch/do_unpack/do_patch are skipped
# entirely and do_compile runs directly against your working tree — so
# local edits are picked up on the next `bitbake data-logger` without a
# commit/push/re-fetch cycle. Remove those two lines (or comment them out)
# to go back to building from the git-fetched SRC_URI above. ---

inherit update-rc.d

INITSCRIPT_NAME = "data-logger"
INITSCRIPT_PARAMS = "defaults 90"

do_compile() {
    # The app's own Makefile already respects CC/CFLAGS/LDFLAGS from the
    # environment (see its `CC ?= gcc` pattern); oe_runmake exports the
    # cross-toolchain bitbake selected for this MACHINE automatically, so
    # no Yocto-specific changes are needed in the app repo's Makefile.
    # Works identically whether S came from the git fetch above or from
    # an EXTERNALSRC override.
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/data-logger ${D}${bindir}/data-logger

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/scripts/data-logger-start-stop.sh ${D}${sysconfdir}/init.d/data-logger
}

FILES:${PN} += "${sysconfdir}/init.d/data-logger"
