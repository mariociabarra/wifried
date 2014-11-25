/* WiFried - Fix for iOS 8.1 WiFi fix
 * Runs inside discoveryd_helper to adjust AWDL interface
 *
 *   - Completely disable WiFi_D2D plugin (prevents AWDL/AirDrop/Peer 2 Peer WiFi (ie, GameKit)
 *
 * Copyright (C) 2014 @mariociabarra
*/

/* GNU Lesser General Public License, Version 3 {{{ */
/* This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */

#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#undef __OSX_AVAILABLE_STARTING
#define __OSX_AVAILABLE_STARTING(x, y)
#include <SystemConfiguration/SystemConfiguration.h>

#include <sys/socket.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <netinet/in.h>

#include "substrate.h"
#include "WiFried.h"

int getModeAndListenForChanges();
void updateAWDLInterface();

struct WiFiManagerClient;
typedef struct WiFiManagerClient* WiFiManagerClientRef;

int WiFiManagerClientSetPower(WiFiManagerClientRef manager, bool on);
int WiFiManagerClientGetPower(WiFiManagerClientRef manager);
WiFiManagerClientRef WiFiManagerClientCreate(CFAllocatorRef allocator, int type);


// called in discoveryd_helper (which runs as root)
void setAWDLIFUp(bool up)
{
    static int sockfd = -1;
    struct ifreq ifr;

    if (sockfd)
        sockfd = socket(AF_INET, SOCK_DGRAM, 0);

    if (sockfd < 0)
    {
        NSLog(@"WiFried: Could not create socket");
        return;
    }

    ifr.ifr_addr.sa_family = AF_INET;
    strncpy(ifr.ifr_name, "awdl0", sizeof (ifr.ifr_name));

    if (ioctl(sockfd, SIOCGIFFLAGS, &ifr) < 0)
    {
        NSLog(@"WiFried: Error getting IFFLAGS from awdl0");
        return;
    }

    int flags = ifr.ifr_flags;
    if (up)
        flags |= IFF_UP;
    else
        flags &= ~IFF_UP;

    ifr.ifr_flags = flags;

    int result = ioctl(sockfd, SIOCSIFFLAGS, &ifr);
    NSLog(@"WiFried Change AWDL interface %s (%d)", up ? "up" : "down", result);
}

// called in discoveryd_helper (which runs as root)
void updateAWDLInterface()
{
        int mode = getModeAndListenForChanges();
        if (mode == WIFID2D_COMPLETELY_OFF_MODE)
            setAWDLIFUp(false);
        else
            setAWDLIFUp(true);
}


static void callback(SCDynamicStoreRef store, CFArrayRef changedKeys, void* info)
{
    if(strcmp(getprogname(), "discoveryd_helper") == 0)
    {
        NSLog(@"WiFried: Settings changed, adjusting AWDL");
        updateAWDLInterface();
    }
}

static SCDynamicStoreRef dynamicStore = nil;

int getModeAndListenForChanges()
{
    int mode = 0;

    if (!dynamicStore)
    {
        dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, CFSTR("wifried"), callback, NULL);
        if(!dynamicStore)
        {
            NSLog(@"WiFried: Could not open store, defaulting to bounce mode");
            return 0;
        }

        if(SCDynamicStoreSetDispatchQueue(dynamicStore, dispatch_get_main_queue()))
            SCDynamicStoreSetNotificationKeys(dynamicStore, (__bridge CFArrayRef)@[ SCWiFried_Key ], NULL);
    }
    CFNumberRef cfMode = SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)SCWiFried_Key);
    if (cfMode)
    {
        mode = [(__bridge NSNumber*)cfMode intValue];
        CFRelease(cfMode);
    }
    return mode;
}

__attribute__((constructor)) static void initialize()
{
    NSLog(@"WiFried: Initializing WiFried");

    if(strcmp(getprogname(), "discoveryd_helper") == 0)
    {
        int mode = getModeAndListenForChanges();
        if (mode == WIFID2D_COMPLETELY_OFF_MODE)
            setAWDLIFUp(false);
        else
            setAWDLIFUp(true);
    }
}
