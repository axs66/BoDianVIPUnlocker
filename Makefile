TARGET := iphone:clang:latest:latest
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = bodian

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BoDianVIPUnlocker

BoDianVIPUnlocker_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
