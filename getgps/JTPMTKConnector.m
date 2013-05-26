//
//  JTPMTKConnector.m
//  getgps
//
//  Created by Jan-Gerd Tenberge on 19.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JTPMTKConnector.h"

@implementation JTPMTKConnector

@synthesize lastLine = _lastLine;

- (id)initWithDevice:(NSString *)deviceFilename {
    self = [super init];
    file = fopen(deviceFilename.UTF8String, "r+");
    line = (char *)malloc(4096*sizeof(char));

    if (file == NULL) {
        perror("Device connection error");
        return nil;
    }
    
    return self;
}

- (void)dealloc {
    fclose(file);
}

- (void)executeCommand:(NSString *)command andWaitForResponse:(NSString *)response {
    command = [self completeCommand:command];
    
    int res = fputs([command cStringUsingEncoding:NSASCIIStringEncoding], file);
    if (res == EOF) {
        perror("Could not send command");
        return;
    }
    
    while (fgets(line, 4096, file)) {
        self.lastLine = [NSString stringWithCString:line encoding:NSASCIIStringEncoding];
        if ([self.lastLine rangeOfString:response].location != NSNotFound) {
            // Got expected response
            break;
        }
        memset(line, 0, sizeof(char)*4096);
    }
}

- (NSString *)completeCommand:(NSString*)command {
    char chk = [self checksumForCommand:command];
    char *realCommand = (char *)malloc((strlen(command.UTF8String)+6)*sizeof(char));
    sprintf(realCommand, "$%s*%02X\r\n", command.UTF8String, chk);
    return [NSString stringWithCString:realCommand encoding:NSUTF8StringEncoding];
}

- (char)checksumForCommand:(NSString*)command {
    char chk = 0;
    char current;
    int i = 0;
    while ((current = command.UTF8String[i])) {
        if (!current) {
            break;
        }
        chk ^= current;
        i++;
    }
    
    return chk;
}

@end
