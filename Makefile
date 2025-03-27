TARGET := iphone:clang:latest:18.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = MyPremiumPal

MyPremiumPal_FILES = MyPremiumPal.m
MyPremiumPal_CFLAGS = -fobjc-arc
MyPremiumPal_INSTALL_PATH = /usr/local/lib

include $(THEOS_MAKE_PATH)/library.mk
