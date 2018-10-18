do::
	/Applications/Xcode.app/Contents/Developer/usr/bin/actool AUPM/Assets/Assets.xcassets --compile AUPM/Resources --platform iphoneos  --minimum-deployment-target 8.0 --app-icon AppIcon --output-partial-info-plist tmp.plist
	/usr/libexec/PlistBuddy -x -c "Merge tmp.plist" AUPM/Resources/Info.plist
	rm tmp.plist
	ibtool --compile AUPM/Resources/LaunchScreen.storyboardc AUPM/Assets/LaunchScreen.storyboard

TARGET = iphone::10.3:8.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AUPM
AUPM_FILES = $(wildcard AUPM/*.m) $(wildcard AUPM/*/*.m) $(wildcard AUPM/Parser/*.c)
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
