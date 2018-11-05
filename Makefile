assets:
	python3 /usr/local/bin/carify/carify.py AUPM/Assets AUPM/Resources
	ibtool --compile AUPM/Resources/LaunchScreen.storyboardc AUPM/Assets/LaunchScreen.storyboard

simulate:
	$(MAKE) all TARGET=simulator::10.3:8.0 TARGET_CODESIGN=
	open -a Simulator
	xcrun simctl boot EC937799-8F51-4701-9A4D-75AE0046AD1E || true #5717909A-01BF-472B-AA03-A28BB64B48E0 || true
	xcrun simctl install EC937799-8F51-4701-9A4D-75AE0046AD1E ./.theos/obj/iphone_simulator/debug/$(APPLICATION_NAME).app
	xcrun simctl launch booted xyz.willy.aupm

TARGET = iphone::10.3:8.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AUPM
AUPM_FILES = $(wildcard AUPM/*.m) $(wildcard AUPM/*/*.m) $(wildcard AUPM/Parser/*.c)
AUPM_LIBRARIES = MobileGestalt
AUPM_FRAMEWORKS = UIKit CoreGraphics WebKit
AUPM_EXTRA_FRAMEWORKS = Realm SpringBoardServices
AUPM_BUNDLE_RESOURCES = AUPM/Resources/
AUPM_CODESIGN_FLAGS = -SAUPM/AUPM.entitlements
AUPM_CFLAGS = -fobjc-arc -DPACKAGE_VERSION='@"$(THEOS_PACKAGE_BASE_VERSION)"' -I ./AUPM/
AUPM_LDFLAGS = -lz

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"AUPM\"" || true
SUBPROJECTS += supersling
include $(THEOS_MAKE_PATH)/aggregate.mk
