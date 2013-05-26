//
//  NSString+NSStringExtensions.m
//  getgps
//
//  Created by Jan-Gerd Tenberge on 27.06.12.
//
//

#import "NSString+NSStringExtensions.h"

@implementation NSString (NSStringExtensions)

unsigned char strToChar (char a, char b) {
    char encoder[3] = {'\0','\0','\0'};
    encoder[0] = a;
    encoder[1] = b;
    return (char) strtol(encoder,NULL,16);
}

- (NSData *)decodeFromHexadecimal {
    const char * bytes = [self cStringUsingEncoding: NSUTF8StringEncoding];
    NSUInteger length = strlen(bytes);
    unsigned char * r = (unsigned char *) malloc(length / 2 + 1);
    unsigned char * index = r;
    
    while ((*bytes) && (*(bytes +1))) {
        *index = strToChar(*bytes, *(bytes +1));
        index++;
        bytes+=2;
    }
    *index = '\0';
    
    NSData * result = [NSData dataWithBytes: r length: length / 2];
    free(r);
    
    return result;
}

@end