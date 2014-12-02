CC=/Applications/XCode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CXX=/Applications/XCode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CFLAGS_NOARCH=-miphoneos-version-min=7.0  -fobjc-arc  -Wno-unknown-pragmas -Wno-deprecated-declarations  -fPIC -O2 -std=gnu99 -isysroot /Developer/iPhoneOS7.0.sdk -Iheaders -I/Developer/iPhoneOS7.0.sdk/usr/include/libxml2 -I. -I../ISXLicensing
CPPFLAGS_NOARCH=-miphoneos-version-min=7.0  -fobjc-arc  -Wall -Werror -Wno-unknown-pragmas -Wno-deprecated-declarations -fPIC -O2 -isysroot /Developer/iPhoneOS7.0.sdk -Iheaders -I/Developer/iPhoneOS7.0.sdk/usr/include/libxml2
CFLAGS=-arch armv7 -arch arm64 $(CFLAGS_NOARCH)
CPPFLAGS=-arch armv7 -arch arm64 $(CPPFLAGS_NOARCH)
CFLAGS32=-arch armv7 $(CFLAGS_NOARCH)
CPPFLAGS32=-arch armv7 $(CPPFLAGS_NOARCH)
CFLAGS64=-arch arm64 $(CFLAGS_NOARCH)
CPPFLAGS64=-arch arm64 $(CPPFLAGS_NOARCH)
LDFLAGS=-arch armv7 -arch arm64 -miphoneos-version-min=7.0 -O2 -isysroot /Developer/iPhoneOS7.0.sdk -F/Developer/iPhoneOS7.0.sdk/System/Library/Frameworks -F/Developer/iPhoneOS7.0.sdk/System/Library/PrivateFrameworks -L.
STRIP=strip

ifeq ($(DEBUG),1)
CFLAGS += -DDEBUG
endif

HOST := $(shell cat ~/.targethost)
EXTRA_DEPLOY_SSH := $(shell cat ~/.wifried_extra)

VERSION ?= 0.4


all: deploy

##############################################################################################

WIFRIED_DISCOVERYD_SRCS_M=wifried-discoveryd.m
WIFRIED_DISCOVERYD_OBJS=$(WIFRIED_DISCOVERYD_SRCS_M:.m=.o)
WIFRIED_DISCOVERYD_DEPENDS=$(WIFRIED_DISCOVERYD_SRCS_M:.m=.d)
WIFRIED_DISCOVERYD_FRAMEWORKS=-framework Foundation -lsubstrate -ljetslammed -framework Sharing -framework MobileWifi -framework DeviceToDeviceManager -framework SystemConfiguration

WIFRIED_DISCOVERYD_HELPER_SRCS_M=wifried-discoveryd_helper.m
WIFRIED_DISCOVERYD_HELPER_OBJS=$(WIFRIED_DISCOVERYD_HELPER_SRCS_M:.m=.o)
WIFRIED_DISCOVERYD_HELPER_DEPENDS=$(WIFRIED_DISCOVERYD_HELPER_SRCS_M:.m=.d)
WIFRIED_DISCOVERYD_HELPER_FRAMEWORKS=-framework Foundation -lsubstrate -ljetslammed -framework SystemConfiguration

WIFRIED_SB_SRCS_M=wifried-springboard.m
WIFRIED_SB_OBJS=$(WIFRIED_SB_SRCS_M:.m=.o)
WIFRIED_SB_DEPENDS=$(WIFRIED_SB_SRCS_M:.m=.d)
WIFRIED_SB_FRAMEWORKS=-framework Foundation -framework UIKit -lsubstrate -framework Sharing -framework SystemConfiguration

.PHONY: clean deploy

deploy: wifried_$(VERSION)_iphoneos-arm.deb
	scp wifried_$(VERSION)_iphoneos-arm.deb root@$(HOST):/tmp/wifried_$(VERSION)_iphoneos-arm.deb
	ssh root@$(HOST) "dpkg -i /tmp/wifried_$(VERSION)_iphoneos-arm.deb; $(EXTRA_DEPLOY_SSH)"

wifried_$(VERSION)_iphoneos-arm.deb: packaging/control.sh packaging/postinst packaging/postrm WiFried-discoveryd.dylib WiFried-discoveryd_helper.dylib WiFried-SB.dylib
		$(eval TEMPDIR := $(shell mktemp -d -t WiFried.deb))
		mkdir -p $(TEMPDIR)/DEBIAN
		mkdir -p $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries
		cp WiFried-discoveryd.dylib $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries/
		cp WiFried-discoveryd.plist $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries/
		cp WiFried-discoveryd_helper.dylib $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries/
		cp WiFried-discoveryd_helper.plist $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries/
		cp WiFried-SB.dylib $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries/
		cp WiFried-SB.plist $(TEMPDIR)/Library/MobileSubstrate/DynamicLibraries/
		packaging/control.sh $(VERSION) > $(TEMPDIR)/DEBIAN/control
		cp packaging/postinst $(TEMPDIR)/DEBIAN/
		cp packaging/postrm $(TEMPDIR)/DEBIAN/
		sudo chown -R 0:0 $(TEMPDIR)
		COPYFILE_DISABLE=1 COPY_EXTENDED_ATTRIBUTES_DISABLE=1 sudo -E dpkg-deb -Zlzma -b $(TEMPDIR) $@
		sudo rm -rf $(TEMPDIR)

WiFried-discoveryd.dylib:	$(WIFRIED_DISCOVERYD_OBJS)
		$(CC) -dynamiclib $(LDFLAGS) $(WIFRIED_DISCOVERYD_FRAMEWORKS) $(WIFRIED_DISCOVERYD_OBJS) -o $@
		ldid -S $@
		#scp %@ root@$(HOST):/Library/MobileSubstrate/DynamicLibraries/

WiFried-discoveryd_helper.dylib:	$(WIFRIED_DISCOVERYD_HELPER_OBJS)
		$(CC) -dynamiclib $(LDFLAGS) $(WIFRIED_DISCOVERYD_HELPER_FRAMEWORKS) $(WIFRIED_DISCOVERYD_HELPER_OBJS) -o $@
		ldid -S $@
		#scp %@ root@$(HOST):/Library/MobileSubstrate/DynamicLibraries/


WiFried-SB.dylib:	$(WIFRIED_SB_OBJS)
		$(CC) -dynamiclib  $(LDFLAGS) $(WIFRIED_SB_FRAMEWORKS) $(WIFRIED_SB_OBJS) -o $@
		ldid -S $@
		#scp %@ root@$(HOST):/Library/MobileSubstrate/DynamicLibraries/

clean:
	rm -f $(WIFRIED_DISCOVERYD_OBJS)
	rm -f $(WIFRIED_DISCOVERYD_DEPENDS)
	rm -f $(WIFRIED_DISCOVERYD_HELPER_OBJS)
	rm -f $(WIFRIED_DISCOVERYD_HELPER_DEPENDS)
	rm -f $(WIFRIED_SB_OBJS)
	rm -f $(WIFRIED_SB_DEPENDS)
	rm -f WiFried-SB.dylib
	rm -f WiFried-discoveryd.dylib
	rm -f WiFried-discoveryd_helper.dylib
	rm -f $(APP_OBJS)
	rm -f $(APP_DEPENDS)

%.d:	%.c
	$(CC) -M -MG $(CFLAGS32) $< > $@

%.d:	%.cpp
	$(CXX) -M -MG $(CPPFLAGS32) $< > $@

%.d:	%.m
	$(CC) -M -MG $(CFLAGS32) $< > $@

%.32.d:	%.c
	$(CC) -M -MG -MT $(patsubst %.d,%.o,$@) $(CFLAGS32) $< > $@

%.64.d:	%.c
	$(CC) -M -MG -MT $(patsubst %.d,%.o,$@) $(CFLAGS64) $< > $@

# vim: set ts=8 sts=8 sw=8 noet:
