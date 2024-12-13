//
//  Sensors.h
//  aspo
//
//  Created by kurt on 12.12.24.
//

#ifndef Sensors_h
#define Sensors_h

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

CFDictionaryRef matching(int page, int usage);

CFArrayRef getPowerValues(CFDictionaryRef sensors);
CFArrayRef getThermalValues(CFDictionaryRef sensors);

double getValueByIndex(CFArrayRef values, int index);

double getCPUThermal(void);
double getCPUVoltage(void);
double getCPUCurrent(void);

double getGPUThermal(void);
double getGPUVoltage(void);
double getGPUCurrent(void);

double getRAMThermal(void);
double getRAMVoltage(void);
double getRAMCurrent(void);

#endif /* Sensors_h */
