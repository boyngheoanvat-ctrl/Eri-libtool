THEOS_DEVICE_IP = localhost
TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EriLibtool

EriLibtool_FILES = Main.mm \
                   $(wildcard 1110/*.cpp) \
                   $(wildcard 1110/*.mm) \
                   $(wildcard 5Toubun/*.cpp) \
                   $(wildcard Esp/*.cpp) \
                   $(wildcard Menu/*.cpp) \
                   $(wildcard Tool/*.cpp) \
                   $(wildcard IMGUI/*.cpp) \
                   IMGUI/backends/imgui_impl_metal.mm \
                   $(wildcard linh_tinh/*.m) \
                   $(wildcard linh_tinh/*.mm) \
                   $(wildcard lib/*.m)

EriLibtool_CFLAGS = -fobjc-arc -IIMGUI -IIncludes -IMenu -IEsp -I1110
EriLibtool_LIBRARIES = dobby

include $(THEOS_MAKEFILES_INC)/tweak.mk
