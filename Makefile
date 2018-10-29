clean::
	python3 /usr/local/bin/carify/carify.py AUPM/Assets AUPM/Resources
	ibtool --compile AUPM/Resources/LaunchScreen.storyboardc AUPM/Assets/LaunchScreen.storyboard

simulate:
	$(MAKE) all TARGET=simulator::10.3:8.0 TARGET_CODESIGN=
	open -a Simulator
	xcrun simctl boot E553D875-BCB7-4463-9054-1EDD2D1AC1D9 || true
	xcrun simctl install E553D875-BCB7-4463-9054-1EDD2D1AC1D9 $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app
	xcrun simctl launch booted xyz.willy.aupm

TARGET = iphone::10.3:8.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AUPM
AUPM_FILES = $(wildcard AUPM/*.m) $(wildcard AUPM/*/*.m) $(wildcard AUPM/Parser/*.c)
AUPM_LIBRARIES = MobileGestalt
AUPM_FRAMEWORKS = UIKit CoreGraphics WebKit
AUPM_EXTRA_FRAMEWORKS = Realm
AUPM_BUNDLE_RESOURCES = AUPM/Resources/
AUPM_CODESIGN_FLAGS = -SAUPM/ent.plist
AUPM_CFLAGS = -fobjc-arc -DPACKAGE_VERSION='@"$(THEOS_PACKAGE_BASE_VERSION)"'
AUPM_LDFLAGS = -lz

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"AUPM\"" || true
SUBPROJECTS += supersling
include $(THEOS_MAKE_PATH)/aggregate.mk
