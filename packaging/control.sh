#!/bin/bash
cat << END_CONTROL_FILE
Package: wifried
Name: WiFried (AWDL Disable)
Version: $1
Architecture: iphoneos-arm
Section: Utilities
Depends: firmware (>= 8), mobilesubstrate
Maintainer: Support Above
Author: Mario Ciabarra <http://twitter.com/@mariociabarra>
Sponsor: ModMyi.com <http://modmyi.com/forums/index.php?styleid=31>
Depiction: http://modmyi.com/info/wifried.d.php
Description: BETA fix for laggy WiFi (at least on iOS 8.1)
END_CONTROL_FILE
