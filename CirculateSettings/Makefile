ARCHS = armv7 arm64
$(shell install_name_tool -id /usr/lib/libcolorpicker_Circulate.dylib lib/libcolorpicker.dylib)

include theos/makefiles/common.mk

BUNDLE_NAME = CirculateSettings
CirculateSettings_FILES = CirculateSettings.mm
CirculateSettings_INSTALL_PATH = /Library/PreferenceBundles
CirculateSettings_FRAMEWORKS = UIKit CoreGraphics QuartzCore
CirculateSettings_PRIVATE_FRAMEWORKS = Preferences
CirculateSettings_LDFLAGS = -Llib -lcolorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CirculateSettings.plist$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/usr/lib/$(ECHO_END)
	$(ECHO_NOTHING)cp lib/libcolorpicker.dylib $(THEOS_STAGING_DIR)/usr/lib/libcolorpicker_Circulate.dylib$(ECHO_END)

include $(THEOS_MAKE_PATH)/aggregate.mk
