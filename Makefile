# 2048 — Puzzle für iPod touch 4 (iOS 6.1, ARMv7), Theos.
TARGET = iphone:clang:7.1:6.0
ARCHS  = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = 2048

2048_FILES  = $(wildcard src/*.m)
2048_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation
2048_CFLAGS  = -fobjc-arc -O2 -Wall

include $(THEOS_MAKE_PATH)/application.mk
