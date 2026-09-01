SUMMARY = "Minimal Raspberry Pi 4 image with the data-logger daemon preinstalled"
LICENSE = "MIT"

inherit core-image

# Adds data-logger (and its init script, via the recipe's FILES) to whatever
# core-image-minimal already includes. Build with:
#   bitbake core-image-data-logger
# This is optional — during active Sprint 1 development it's often faster
# to `bitbake data-logger` alone and deploy just the binary/package rather
# than rebuilding a full image each time.
IMAGE_INSTALL:append = " data-logger"
