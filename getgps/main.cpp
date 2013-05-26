//
//  main.cpp
//  getgps
//
//  Created by Jan-Gerd Tenberge on 19.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <iostream>
#include <stdio.h>
#include <fcntl.h>
#include <libkern/OSByteOrder.h>

FILE *file;
char *line = (char *)malloc(sizeof(char)*4096);
size_t length;

#pragma pack(push)
#pragma pack(2)
typedef struct {
    float utcTime;
    char valid[2];
    double lat;
    double lon;
    float height;
    float speed;
    char recReason[2];
} gpsStamp;
#pragma pack(pop)

gpsStamp stampFromChars(const char *input);
void executeCommandAndWaitForResponse (const char *command, const char *response);
char checksum (const char *command);
char *completeCommand (const char *command);

int main(int argc, const char * argv[]) {
    file = fopen("/dev/cu.usbmodemfd1410", "r+");
    if (file == NULL) {
        perror("Could not connect to device");
        return 1;
    }

    const char *command;
    
    if (argc > 1) {
        command = argv[1];
        printf("Executing custom command: %s\n", command);
        executeCommandAndWaitForResponse(command, "PMTK");
        printf("Answer: %s\n", line);
        fclose(file);
        return 0;
    }
    
    printf("Disabling logging\n");
    executeCommandAndWaitForResponse("PMTK182,5", "PMTK001,182,5,3*22");
    printf("Logging disabled\n");

    printf("Reading memory\n");
    char *readCommand = (char *)malloc(sizeof(char)*30);
    for (int k=0; k<4096; k+=400) {
        sprintf(readCommand, "PMTK182,7,%i,400", k);
        executeCommandAndWaitForResponse(readCommand, "PMTK");
        char *offset = line;
        while (strstr(offset, "AAAAAAAAAA0706010000BBBBBBBB") != NULL) {
            offset = strstr(offset, "AAAAAAAAAA0706010000BBBBBBBB")+28;
        };
        char *data = offset;
        
        gpsStamp stamp = {0x0};
        while (stamp.lat >= 0.0) {
            stamp = stampFromChars(data);
            printf("%f: %f, %f\n", stamp.utcTime, stamp.lat, stamp.lon);
            data += 34*2;
        }
    }
    printf("Memory read\n");
    
    /*
    printf("Formatting reader\n");
    executeCommandAndWaitForResponse("PMTK182,6,1", "PMTK");
    printf("Formatted\n");
    */
    
    printf("Enabling logging\n");
    executeCommandAndWaitForResponse("PMTK182,4", "PMTK");
    printf("Logging enabled\n");
    
    fclose(file);
}

gpsStamp stampFromChars(const char *input) {
    gpsStamp stamp;
    for (int i=0; i<sizeof(stamp); i++) {
        sscanf(input+(2*i), "%02x", ((char *)(&stamp))+i);
    }
    return stamp;
}

void executeCommandAndWaitForResponse (const char *command, const char *response) {
    command = completeCommand(command);

    int res = fputs(command, file);
    if (res == EOF) {
        perror("Could not send command");
        fclose(file);
        return;
    }

    while ((line = fgetln(file, &length))) {
        if (strstr(line, response) != NULL) {
            // Got expected response
            break;
        }
        memset(line, 0, sizeof(char)*4096);
    }
}

char *completeCommand (const char *command) {
    char chk = checksum(command);
    unsigned int commandSize = strlen(command);
    char *realCommand = (char *)malloc((commandSize+6)*sizeof(char));
    sprintf(realCommand, "$%s*%02X\r\n", command, chk);
    return realCommand;
}

char checksum (const char *command) {
    char chk = 0;
    char current;
    int i = 0;
    while ((current = command[i])) {
        if (!current) {
            break;
        }
        chk ^= current;
        i++;
    }

    return chk;
}