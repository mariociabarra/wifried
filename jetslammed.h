/* jetslammed) - Ability to adjust jetsam memory limits for iOS tweaks
 *
 * From within the target process, use:
 *      jetslammed_updateWaterMark(350, "mytweakname");
 *
 * Default watermark levels are in /System/Library/LaunchDaemons/com.apple.jetsamproperties.<device id>.plist
 *  ie, com.apple.SpringBoard on iOS 8 for iPhone6 is JetsamMemoryLimit=240
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

#define MAX_REQUEST_NAME 1024
#include <signal.h>


// Primary function
extern int jetslammed_updateWaterMark(int highWatermarkMB, char* requester);


// Helper functions if you want to use
extern int jetslammed_updateWaterMarkForPID(int highWatermarkMB, char* requester, int pid);
extern int getCurrentHighwatermark(int pid);


struct JetslammedRequest {
    OSType          magic;                          // must be kPacketMagic
    int             memorySize;                     // kPacketTypeGoodbye etc
    char            requestor[MAX_REQUEST_NAME];    // kPacketIDNone or some other value
    pid_t           pid;                            // includes size of header itself
};