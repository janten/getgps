//
//  main.m
//  getgps
//
//  Created by Jan-Gerd Tenberge on 19.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JTPMTKConnector.h"
#import "NSString+NSStringExtensions.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"Device attachment detected. Sleeping for 5 seconds.");
        sleep(5);
        
        // Search for /dev/cu.usbmodem*
        NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil];
        NSString *deviceFilename = nil;
        for (NSString *filename in filenames) {
            if ([filename rangeOfString:@"cu.usbmodem"].location != NSNotFound) {
                deviceFilename = [NSString stringWithFormat:@"/dev/%@", filename];
                break;
            }
        }
        
        if (deviceFilename == nil) {
            NSLog(@"Could not find device");
            return 1;
        }
        
        // Establish device connection
        JTPMTKConnector *connector = [[JTPMTKConnector alloc] initWithDevice:deviceFilename];
        if (connector == nil) {
            NSLog(@"Could not connect to GPS device");
            return 1;
        } 

        // Use notification center on Montain Lion
        Class notificationCenterClass = NSClassFromString(@"NSUserNotificationCenter");
        if ((notificationCenterClass != nil)) {
            id notificationCenter = [notificationCenterClass performSelector:@selector(defaultUserNotificationCenter)];
            id notification = [[NSClassFromString(@"NSUserNotification") alloc] init];
            [notification performSelector:@selector(setTitle:) withObject:@"Downloading GPS tracks"];
            [notification performSelector:@selector(setSubtitle:) withObject:@"Do not disconnect device"];
            [notificationCenter performSelector:@selector(deliverNotification:) withObject:notification];
        } else {
            NSLog(@"Starting GPS download");
        }
        
        NSString *command;
        NSLog(@"File: %s", deviceFilename.UTF8String);
        
        // Send custom command to device, if specified
        if (argc > 1) {
            command = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
            NSLog(@"Executing custom command: %@", command);
            [connector executeCommand:command andWaitForResponse:@"PMTK"];
            return 0;
        }
        
        // Disable device logging while downloading data.
        NSLog(@"Disabling logging");
        [connector executeCommand:@"PMTK182,5" andWaitForResponse:@"PMTK001,182,5,3*22"];
        NSLog(@"Logging disabled");

        // Get device data and save to `date`.gpx
        NSLog(@"Reading memory ");
        NSString *filename = [NSString stringWithFormat:@"%@.gps", [[NSDate date] description]];
        [[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        NSData *currentData;
        NSString *realData;
        for (int i=0; ; i += 400) {
            command = [NSString stringWithFormat:@"PMTK182,7,%i,400", i]; // Reads 400 Bytes(?)
            [connector executeCommand:command andWaitForResponse:@"PMTK"]; // "PMTK" signals end of data
            realData = [connector.lastLine componentsSeparatedByString:@","].lastObject;
            realData = [[realData componentsSeparatedByString:@"*"] objectAtIndex:0];
            currentData = [realData decodeFromHexadecimal];

            BOOL isEmpty = YES;
            const unsigned char *bytes = currentData.bytes;
            for (int j=0; j<currentData.length/2; j++) {
                if (bytes[j] != 0xFF) {
                    isEmpty = NO;
                }
            }

            // Stop reading when receiving empty log entries
            if (isEmpty) {
                NSLog(@"Empty response");
                break;
            }
            
            [fileHandle writeData:currentData];
        }
        [fileHandle closeFile];
        NSLog(@"Memory read");
        

        // Clear the device memory so the next log begins at the first memory address
        NSLog(@"Formatting reader");
        [connector executeCommand:@"PMTK182,6,1" andWaitForResponse:@"PMTK"];
        NSLog(@"Formatted");

        // Re-enable logging
        NSLog(@"Enabling logging");
        [connector executeCommand:@"PMTK182,4" andWaitForResponse:@"PMTK"];
        NSLog(@"Logging enabled");
        
        // Destroy connector, disconnect from device
        connector = nil;

        // Mountain Lion
        if ((notificationCenterClass != nil)) {
            id notificationCenter = [notificationCenterClass performSelector:@selector(defaultUserNotificationCenter)];
            id notification = [[NSClassFromString(@"NSUserNotification") alloc] init];
            [notification performSelector:@selector(setTitle:) withObject:@"GPS tracks copied"];
            [notification performSelector:@selector(setSubtitle:) withObject:filename];
            [notificationCenter performSelector:@selector(deliverNotification:) withObject:notification];
        } else {
            NSLog(@"Tracks saved to %@", filename);
        }
        
        // Stay around as long as the device is connected.
        // This prevents re-launches when used as a LaunchAgent
        while ([[NSFileManager defaultManager] fileExistsAtPath:deviceFilename]) {
            sleep(30);
        }
        
        NSLog(@"%@ is gone. Bye.", deviceFilename);
    }
    return 0;
}
