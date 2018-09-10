TARGET = iphone::10.3:8.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AUPM
AUPM_FILES = $(wildcard AUPM/*.m) $(wildcard AUPM/*/*.m) $(wildcard AUPM/Parser/*.c)
AUPM_FRAMEWORKS = UIKit CoreGraphics WebKit
AUPM_EXTRA_FRAMEWORKS = Realm
AUPM_BUNDLE_RESOURCES = AUPM/Resources/
AUPM_CODESIGN_FLAGS = -SAUPM/ent.plist
AUPM_CFLAGS = -fobjc-arc
AUPM_LDFLAGS = -lz

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"AUPM\"" || true
SUBPROJECTS += supersling
include $(THEOS_MAKE_PATH)/aggregate.mk
