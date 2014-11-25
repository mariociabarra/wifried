/* WiFried) - Fix for iOS 8.1 WiFi fix
 * wifried_springboard.m
 *
 * Handles UI within the AirDrop UI.
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

#include <UIKit/UIKit.h>

#undef __OSX_AVAILABLE_STARTING
#define __OSX_AVAILABLE_STARTING(x, y)
#include <SystemConfiguration/SystemConfiguration.h>

#include "substrate.h"
#include "WiFried.h"
#include "SBCCButtonLikeSectionView.h"


#define GET_IVAR(obj, prop) object_getIvar(obj, class_getInstanceVariable(object_getClass(obj), prop))

extern NSString* SFLocalizedStringForKey(NSString* key);

int getMode()
{
    int mode = 0;
    // ignoring callbacks as toggling between completely off and bounce requires restart
    SCDynamicStoreRef dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, CFSTR("wifried"), NULL, NULL);
    if(!dynamicStore)
    {
        NSLog(@"WiFried: Could not open store, defaulting to bounce mode");
        return 0;
    }
    CFNumberRef cfMode = SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)SCWiFried_Key);
    if (cfMode)
    {
        mode = [(__bridge NSNumber*)cfMode intValue];
        CFRelease(cfMode);
    }
    CFRelease(dynamicStore);
    return mode;
}

void saveMode(int mode)
{
    if (mode != getMode())
    {
        SCDynamicStoreRef dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, CFSTR("wifried"), NULL, NULL);
        if(!dynamicStore)
        {
            NSLog(@"WiFried: Could not open store for saving mode");
            return;
        }
        SCDynamicStoreSetValue(dynamicStore, (CFStringRef)SCWiFried_Key, (__bridge CFStringRef)@(mode));
        NSLog(@"WiFried: Set MODE :%d", mode);
        CFRelease(dynamicStore);
        // discoveryd will exit on changes
    }
}

IMP original_SF_discoverableModeActionSheet_;
// SFAirDropDiscoveryController discoverableModeActionSheet
UIActionSheet* wifried_SF_discoverableModeActionSheet_(id self, SEL _cmd)
{
    UIActionSheet* actionSheet = nil;

    actionSheet= [[UIActionSheet alloc] initWithTitle: SFLocalizedStringForKey(@"DISCOVERABLE_ACTION_SHEET_TITLE")
                    delegate: self  cancelButtonTitle: SFLocalizedStringForKey(@"CANCEL_BUTTON_TITLE")
                    destructiveButtonTitle: nil otherButtonTitles: @"WiFried (D2DWiFi Off)", SFLocalizedStringForKey(@"OFF_BUTTON_TITLE"),
                     SFLocalizedStringForKey(@"CONTACTS_ONLY_BUTTON_TITLE"), SFLocalizedStringForKey(@"EVERYONE_BUTTON_TITLE"), nil];

    return actionSheet;
}

void (*original_SF_setDiscoverableMode_)(id self, SEL _cmd, NSInteger mode) = 0;
// SFAirDropDiscoveryController setDiscoverableMode:
void wifried_SF_setDiscoverableMode_(id self, SEL _cmd, NSInteger mode)
{
    if (mode == WIFID2D_COMPLETELY_OFF_MODE)
    {
        // turn off completely WIFID2D_COMPLETELY_OFF_MODE
        NSLog(@"WiFried: Setting WiFiD2D Off Mode");
        original_SF_setDiscoverableMode_(self, _cmd, 0);
        saveMode(WIFID2D_COMPLETELY_OFF_MODE);
    }
    else
    {
        original_SF_setDiscoverableMode_(self, _cmd, mode -1);
        saveMode(BOUNCE_MODE);
    }
}

void (*original_SFCC_updateAirDropControlAsEnabled_)(id self, SEL _cmd, BOOL enabled) = 0;
// SBCCAirStuffSectionController _updateAirDropControlAsEnabled:
void wifried_SFCC_updateAirDropControlAsEnabled_(id self, SEL _cmd, BOOL enabled)
{
    original_SFCC_updateAirDropControlAsEnabled_(self, _cmd, enabled);
    if (getMode() == WIFID2D_COMPLETELY_OFF_MODE)
    {
        NSLog(@"WiFried: Updating CC UI");
        SBCCButtonLikeSectionView* button = GET_IVAR(self, "_airDropSection");
        [button setSelected: false];
        [button setText: @"AirDrop: WiFried"];
    }
}

__attribute__((constructor)) static void initialize()
{
    NSLog(@"WiFried: Initializing WiFried");
    static bool hooked = false;
    hooked = true;
    MSHookMessageEx(NSClassFromString(@"SFAirDropDiscoveryController"), @selector(setDiscoverableMode:), (IMP)wifried_SF_setDiscoverableMode_, (IMP *)&original_SF_setDiscoverableMode_);
    MSHookMessageEx(NSClassFromString(@"SFAirDropDiscoveryController"), @selector(discoverableModeActionSheet), (IMP)wifried_SF_discoverableModeActionSheet_, (IMP *)&original_SF_discoverableModeActionSheet_);
    MSHookMessageEx(NSClassFromString(@"SBCCAirStuffSectionController"), @selector(_updateAirDropControlAsEnabled:), (IMP)wifried_SFCC_updateAirDropControlAsEnabled_, (IMP *)&original_SFCC_updateAirDropControlAsEnabled_);

}
