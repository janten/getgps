//
//  JTPMTKConnector.h
//  getgps
//
//  Created by Jan-Gerd Tenberge on 19.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <fcntl.h>
#include <libkern/OSByteOrder.h>

@interface JTPMTKConnector : NSObject {
    FILE *file;
    char *line;
}

@property (strong) NSString* lastLine;

- (id)initWithDevice:(NSString *)deviceFilename;
- (void)executeCommand:(NSString *)command andWaitForResponse:(NSString *)response;
- (NSString *)completeCommand:(NSString*)command;
- (char)checksumForCommand:(NSString*)command;

@end
