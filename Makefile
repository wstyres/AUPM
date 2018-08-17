include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AUPM
AUPM_FILES = main.m AUPMAppDelegate.m AUPMRootViewController.m
AUPM_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"AUPM\"" || true
