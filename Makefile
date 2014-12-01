ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = Circulate
Circulate_FILES = Tweak.xm
Circulate_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
Circulate_CFLAGS = -Wno-error
export GO_EASY_ON_ME := 1
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += CirculateSettings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete
after-install::
	install.exec "killall -9 backboardd"
