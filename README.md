# Project Overview
https://github.com/ibrahimjaime/final-proyect-assignment-ibrahimjaime-/wiki/Project-Overview

# Project Schedule
https://github.com/users/ibrahimjaime/projects/4/views/1


# Yocto Data Logger Platform

This repository holds the **platform layer** for the Data Logging
System: a custom Yocto/OpenEmbedded layer (`meta-data-logger`) that builds
the [`data-logger` app](https://github.com/ibrahimjaime/final-project-assignment-apps-ibrahimjaime)
for the Raspberry Pi 4 and installs it into a bootable image.

## Two repos, one system

This project deliberately spans **two repositories** with a clean split of
responsibility:

| Repo | Contents | Changes when... |
|---|---|---|
| `final-project-assignment-apps` (app repo) | C source, Makefile, `scripts/data-logger-start-stop.sh` | the daemon's logic or behavior changes |
| `yocto-data-logger-platform` (this repo) | Bitbake recipe, layer config, image definition | the target/board, init system, or how the app is packaged changes |

The bitbake recipe in this repo (`recipes-apps/data-logger/data-logger_1.0.bb`)
fetches the app repo via `SRC_URI = "git://..."` and builds it with the
Yocto-selected cross toolchain — it does not vendor or duplicate the app's
source. This repo also does **not** contain `poky` or `meta-raspberrypi`
themselves; those remain their own separate clones (reuse the ones from
earlier course assignments if you already have them).

## Repository layout

```
.
├── README.md
├── meta-data-logger/                     # the actual Yocto layer
│   ├── conf/
│   │   └── layer.conf                      # registers this layer with bitbake
│   ├── COPYING.MIT                         # required license file for a Yocto layer
│   ├── recipes-apps/
│   │   └── data-logger/
│   │       └── data-logger_1.0.bb          # fetch, cross-compile, install the daemon
│   └── recipes-core/
│       └── images/
│           └── core-image-data-logger.bb   # optional: full image with the daemon baked in
├── build-templates/                      # reference conf files, NOT auto-applied
│   ├── local.conf.sample                   # MACHINE = raspberrypi4-64, UART, etc.
│   └── bblayers.conf.sample                # registers meta-data-logger alongside poky/meta-raspberrypi
└── scripts/
    └── setup-build.sh                    # optional one-time bootstrap helper
```

## Why a layer instead of just the SDK

Earlier in this project, the app repo's README documents cross-compiling
with a **standalone Yocto SDK** (`bitbake -c populate_sdk`) — that's the
fast path for iterating on the daemon itself: build, `scp`, test, repeat,
without touching image builds at all.

This repo is the complementary, longer-term path: once the daemon is
stable, `meta-data-logger` lets `bitbake core-image-data-logger` produce a
**complete bootable image** with the daemon already installed and
registered with the init system — the deliverable you'd actually flash to
an SD card for a final demo, rather than something you `scp` on top of an
existing image by hand.

## Setup

**If you already have a poky + meta-raspberrypi checkout** from earlier
coursework, skip the clone step — just:

1. Clone this repo alongside your existing `poky` checkout.
2. Add `meta-data-logger`'s absolute path to your existing
   `build/conf/bblayers.conf` (see `build-templates/bblayers.conf.sample`
   for the line to add).
3. Add `MACHINE = "raspberrypi4-64"` to `build/conf/local.conf` if it
   isn't already set (see `build-templates/local.conf.sample`).

**Starting from scratch**, `scripts/setup-build.sh` clones `poky` and
`meta-raspberrypi`, initializes a build directory, and drops the config
templates in for you to review and merge:

```sh
./scripts/setup-build.sh
```

## Building

```sh
# From inside poky/build, after sourcing oe-init-build-env and merging
# the config templates above:

bitbake data-logger              # build just the app package
bitbake core-image-data-logger   # build a full bootable image including it
```

Flash the resulting image (`tmp/deploy/images/raspberrypi4-64/`) to an SD
card the same way you did for prior course assignments, or, for faster
iteration, keep using the standalone SDK + manual `scp` workflow documented
in the app repo while the daemon is still under active development.

## Updating the pinned app version

`SRCREV = "${AUTOREV}"` in the recipe always fetches the app repo's latest
`master` at build time — convenient during Sprint 1, but not reproducible.
Once a sprint's work is stable, pin it to a real commit instead:

```
SRCREV = "<full commit hash from final-project-assignment-apps>"
```

so a clean `bitbake -c cleanall data-logger && bitbake data-logger` always
rebuilds the exact same app version rather than whatever `master` currently
points to.