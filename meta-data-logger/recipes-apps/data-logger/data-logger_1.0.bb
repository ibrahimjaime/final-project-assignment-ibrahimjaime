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

# --- Fetch: point this at your actual app repo and pin a real commit for
# reproducible builds once Sprint 1 stabilizes. AUTOREV is convenient
# during active development but means every clean build re-fetches HEAD. ---
SRC_URI = "git://github.com/ibrahimjaime/final-project-assignment-apps-ibrahimjaime.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

PV = "1.0+git${SRCPV}"
S = "${WORKDIR}/git"

inherit update-rc.d

INITSCRIPT_NAME = "data-logger"
INITSCRIPT_PARAMS = "defaults 90"

do_compile() {
    # The app's own Makefile already respects CC/CFLAGS/LDFLAGS from the
    # environment (see its `CC ?= gcc` pattern); oe_runmake exports the
    # cross-toolchain bitbake selected for this MACHINE automatically, so
    # no Yocto-specific changes are needed in the app repo's Makefile.
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/data-logger ${D}${bindir}/data-logger

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/scripts/data-logger-start-stop.sh ${D}${sysconfdir}/init.d/data-logger
}

FILES:${PN} += "${sysconfdir}/init.d/data-logger"
