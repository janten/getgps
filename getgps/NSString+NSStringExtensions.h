//
//  NSString+NSStringExtensions.h
//  getgps
//
//  Created by Jan-Gerd Tenberge on 27.06.12.
//
//

#import <Foundation/Foundation.h>

#import <stdio.h>
#import <stdlib.h>
#import <string.h>

@interface NSString (NSStringExtensions)
- (NSData *)decodeFromHexadecimal;
@end