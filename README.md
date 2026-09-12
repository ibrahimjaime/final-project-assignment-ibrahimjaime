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
| [`final-project-assignment-apps-ibrahimjaime`](https://github.com/ibrahimjaime/final-project-assignment-apps-ibrahimjaime) (app repo) | C source, Makefile, `scripts/data-logger-start-stop.sh` | the daemon's logic or behavior changes |
| `yocto-data-logger-platform` (this repo) | Bitbake recipe, layer config, image definition, `poky`/`meta-raspberrypi` submodules, build/clean scripts | the target/board, init system, or how the app is packaged changes |

The bitbake recipe in this repo (`recipes-apps/data-logger/data-logger_1.0.bb`)
fetches the app repo via `SRC_URI = "git://..."` by default and builds it
with the Yocto-selected cross toolchain — it does not vendor or duplicate
the app's source (see **Source modes** below for the local-development
alternative).

**`poky` and `meta-raspberrypi`** *are* tracked in this repo, but as **git
submodules** pinned to the `kirkstone` branch (see `.gitmodules`) — this
records which commit of each to use, without vendoring their source.

## Repository layout

```
.
├── README.md
├── .gitmodules                           # pins poky and meta-raspberrypi to kirkstone
├── poky/                                 # submodule (Yocto core)
├── meta-raspberrypi/                     # submodule (sibling of poky, not nested inside it)
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
│   ├── local.conf.sample                     # MACHINE = raspberrypi4-64, UART, etc.
│   ├── bblayers.conf.sample                  # registers meta-data-logger alongside poky/meta-raspberrypi
│   └── local.conf.local-dev-override.sample  # EXTERNALSRC snippet, see Source modes below
├── build.sh                              # automated build: submodules → layers → image
├── clean.sh                              # sstate/work clean, plus local app checkout clean
└── scripts/
    └── setup-build.sh                    # one-time bootstrap helper (used by build.sh)
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

**On new machine, after cloning this repo:**

```sh
git submodule update --init --recursive
```

This fetches `poky` and `meta-raspberrypi` at the commits this repo has
pinned. Both will show as a detached `HEAD` at a specific commit — that's
expected for submodules, not an error. `build.sh` (below) also runs this
step automatically, so you can skip it and just run `build.sh` directly.

## Building

The easiest path is the automated script, which handles submodules, the
build directory, `local.conf`/`bblayers.conf` settings, and both required
layers idempotently — safe to re-run on a partially-set-up machine:

```sh
./build.sh
```

Equivalent manual steps, if you want to run bitbake commands yourself
(useful once the build environment already exists and you just want to
target a specific recipe):

```sh
cd poky
source oe-init-build-env build
bitbake data-logger              # build just the app package
bitbake core-image-data-logger   # build a full bootable image including it
```

Flash the resulting image
(`poky/build/tmp/deploy/images/raspberrypi4-64/*.wic.bz2`) to an SD card —
`dd` it the same way as prior course assignments — or, for faster
iteration, keep using the standalone SDK + manual `scp` workflow documented
in the app repo while the daemon is still under active development.

## Cleaning

`clean.sh` undoes build state without needing to remember the exact
`bitbake -c cleansstate` / `make clean` incantations each time — and
specifically guards against a stale-native-binary bug we hit once during
development (a leftover x86-64 build silently getting packaged into an
aarch64 image because `make`'s timestamp check saw nothing to rebuild).

```sh
./clean.sh              # sstate-clean data-logger, and clean the local app
                         # checkout too if you're using EXTERNALSRC (auto-detected —
                         # never needs a hardcoded path)
./clean.sh --sstate     # only the sstate/work clean
./clean.sh --app        # only the local app checkout clean
./clean.sh --full       # also wipe tmp/, sstate-cache/, cache/ — a true
                         # from-scratch rebuild (slow: re-does base layers too)
```

## Source modes: git fetch vs. local working copy

The recipe defaults to fetching the app repo via `SRC_URI = "git://..."` —
the reproducible path: anyone cloning this layer and running `bitbake
data-logger` gets the same source, no machine-specific setup required.

While actively developing the daemon, re-fetching from git on every build
is slow and means committing/pushing just to test a one-line change. For
that, use **`externalsrc`** to point bitbake at your local working copy
directly — `do_fetch`/`do_unpack`/`do_patch` are skipped entirely and
`do_compile` runs straight against your local files.

**This override must live in your own `poky/build/conf/local.conf`, never
in this repo** — `local.conf` is a generated, machine-local file, so it's
the correct place for an absolute path that's specific to your machine
and would otherwise get committed by accident. See
`build-templates/local.conf.local-dev-override.sample` for the exact two
lines to add:

```
INHERIT += "externalsrc"
EXTERNALSRC:pn-data-logger = "/absolute/path/to/final-project-assignment-apps-ibrahimjaime"
```

Remove those two lines (or comment them out) to switch back to the
git-fetched, reproducible path — no recipe changes needed either way.

## Updating the pinned app version

`SRCREV ?= "${AUTOREV}"` in the recipe always fetches the app repo's
latest commit on its default branch at build time — convenient during
active development, but not reproducible.

> **Check this first:** confirm which branch your app repo
> (`final-project-assignment-apps-ibrahimjaime`) actually uses as its
> default — `main` or `master` — and make sure the `branch=` parameter in
> `data-logger_1.0.bb`'s `SRC_URI` matches exactly. A mismatch here fails
> `do_fetch` outright.

Once a sprint's work is stable, pin `SRCREV` to a real commit instead of
`AUTOREV`:

```
SRCREV = "<full commit hash from final-project-assignment-apps-ibrahimjaime>"
```

so a clean `./clean.sh --full && ./build.sh` always rebuilds the exact
same app version rather than whatever the branch currently points to.

## Build and Copy Only the App to the Raspberry Pi

1. Remove the previous binary:

   ```bash
   ./clean.sh --app
   ```

2. Build the app:

   ```bash
   cd poky/
   bitbake data-logger
   ```

3. Stop the execution of the app on the raspberry:

   ```bash
   ssh root@<pi-id>
   /etc/init.d/data-logger stop
   ```

4. Copy the binary to the raspberry:

   ```bash
   scp data-logger root@<pi-id>:/usr/bin/data-logger
   ```
5. Start the app:

   ```bash
   /etc/init.d/data-logger start
   ```

## Flash the Yocto Image to an SD Card

1. Identify the SD card device:

   ```bash
   lsblk
   ```

2. Unmount its partitions (replace `/dev/sdbX` with the partitions shown by `lsblk`):

   ```bash
   sudo umount /dev/sdb1
   sudo umount /dev/sdb2
   ```

3. Navigate to the directory containing the generated image:

   ```bash
   cd ~/Documents/course/final-project-assignment-yocto/poky/build/tmp/deploy/images/raspberrypi4-64/
   ```

4. Flash the image to the SD card. **Use the device (`/dev/sdb`), not a partition (`/dev/sdb1`):**

   ```bash
   sudo bzcat core-image-data-logger-raspberrypi4-64.wic.bz2 | sudo dd of=/dev/sdb bs=4M status=progress conv=fsync
   ```

5. Flush pending writes:

   ```bash
   sync
   ```

6. Verify the resulting partitions:

   ```bash
   lsblk -f /dev/sdb
   ```

> **Warning:** Make sure `/dev/sdb` is the SD card before running `dd`, as it will overwrite the entire device.
