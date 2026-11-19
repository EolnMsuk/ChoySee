include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ChoySeePrefs

ChoySeePrefs_FILES = $(wildcard *.m) $(wildcard *.x) ../Shared.m ../ChoicyPrefsMigrator.m $(wildcard ../external/litehook/src/*.c) $(wildcard ../external/ChOma/src/*.c)
ChoySeePrefs_INSTALL_PATH = /Library/PreferenceBundles
ChoySeePrefs_FRAMEWORKS = UIKit
ChoySeePrefs_PRIVATE_FRAMEWORKS = Preferences MobileCoreServices
ChoySeePrefs_EXTRA_FRAMEWORKS = AltList
ChoySeePrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I../external/ChOma/src -I../external/litehook/src
# LiteHook's Mach return code can be unused in final builds.
../external/litehook/src/litehook.c_CFLAGS += -Wno-error=unused-variable
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
ChoySeePrefs_LIBRARIES += roothide
endif

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ChoySeePrefs.plist"$(ECHO_END)
