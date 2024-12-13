//
//  Sensors.m
//  aspo
//
//  Created by kurt on 10.12.24.
//
//  This is an apple silicon sensors fetcher inspired by https://github.com/freedomtan/sensors/blob/master/sensors/sensors.m
//  This script is just a modified version to give me access to the values within swift
//  their license:
//
// BSD 3-Clause License

// Copyright (c) 2016-2018, "freedom" Koan-Sin Tan
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.

// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.

// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <Foundation/Foundation.h>
#include <stdio.h>

// Declarations from other IOKit source code

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
int IOHIDEventSystemClientSetMatchingMultiple(IOHIDEventSystemClientRef client, CFArrayRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t , int32_t, int64_t);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

// create a dict ref, like for temperature sensor {"PrimaryUsagePage":0xff00, "PrimaryUsage":0x5}
CFDictionaryRef matching(int page, int usage)
{
    CFNumberRef nums[2];
    CFStringRef keys[2];

    keys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
    keys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);
    nums[0] = CFNumberCreate(0, kCFNumberSInt32Type, &page);
    nums[1] = CFNumberCreate(0, kCFNumberSInt32Type, &usage);

    CFDictionaryRef dict = CFDictionaryCreate(0, (const void**)keys, (const void**)nums, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    return dict;
}
// from IOHIDFamily/IOHIDEventTypes.h
// e.g., https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/IOHIDEventTypes.h.auto.html

#define IOHIDEventFieldBase(type)   (type << 16)
#define kIOHIDEventTypeTemperature  15
#define kIOHIDEventTypePower        25

CFArrayRef getPowerValues(CFDictionaryRef sensors) {
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, sensors);
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system);

    long count = CFArrayGetCount(matchingsrvs);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypePower, 0, 0);

        CFNumberRef value;
        if (event != 0) {
            double temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypePower));
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        } else {
            double temp = 0;
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        }
        CFArrayAppendValue(array, value);
    }
    return array;
}

CFArrayRef getThermalValues(CFDictionaryRef sensors) {
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, sensors);
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system);

    long count = CFArrayGetCount(matchingsrvs);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0); // here we use ...CopyEvent

        CFNumberRef value;
        if (event != 0) {
            double temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        } else {
            double temp = 0;
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        }
        CFArrayAppendValue(array, value);
    }
    return array;
}

double getValueByIndex(CFArrayRef values, int index) {
    CFNumberRef value = CFArrayGetValueAtIndex(values, index);
    double temp = 0.0;
    CFNumberGetValue(value, kCFNumberDoubleType, &temp);

    return temp;
}

double getCPUThermal() {
    CFDictionaryRef thermalSensors = matching(0xff00, 5);
    CFArrayRef values = getThermalValues(thermalSensors);
    
    double atIndex8 = getValueByIndex(values, 8);
    double atIndex18 = getValueByIndex(values, 18);
    double atIndex44 = getValueByIndex(values, 44);
    double atIndex17 = getValueByIndex(values, 17);
    
    CFRelease(values);

    double average = (atIndex8 + atIndex18 + atIndex44 + atIndex17) / 4;
    return average;
}

double getCPUVoltage() {
    CFDictionaryRef voltageSensors = matching(0xff08, 3);
    CFArrayRef values = getPowerValues(voltageSensors);
    
    double atIndex13 = getValueByIndex(values, 13);
    double atIndex12 = getValueByIndex(values, 12);

    CFRelease(values);
    
    double average = (atIndex12 + atIndex13) / 2;
    return average / 1000;
}

double getCPUCurrent() {
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    CFArrayRef values = getPowerValues(currentSensors);
    
    double atIndex6 = getValueByIndex(values, 6);
    double atIndex17 = getValueByIndex(values, 17);

    CFRelease(values);
    
    double average = (atIndex6 + atIndex17) / 2;
    return average / 1000;
}

double getGPUThermal() {
    CFDictionaryRef thermalSensors = matching(0xff00, 5);
    CFArrayRef values = getThermalValues(thermalSensors);
    
    double atIndex16 = getValueByIndex(values, 16);
    double atIndex43 = getValueByIndex(values, 43);

    CFRelease(values);
    
    double average = (atIndex16 + atIndex43) / 2;
    return average;
}

double getGPUVoltage() {
    CFDictionaryRef voltageSensors = matching(0xff08, 3);
    CFArrayRef values = getPowerValues(voltageSensors);
    
    double atIndex22 = getValueByIndex(values, 22);
    double atIndex21 = getValueByIndex(values, 21);

    CFRelease(values);
    
    double average = (atIndex22 + atIndex21) / 2;
    return average / 1000;
}

double getGPUCurrent() {
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    CFArrayRef values = getPowerValues(currentSensors);
    
    double atIndex14 = getValueByIndex(values, 14);
    double atIndex17 = getValueByIndex(values, 17);

    CFRelease(values);
    
    double average = (atIndex14 + atIndex17) / 2;
    return average / 1000;
}

double getRAMThermal() {
    CFDictionaryRef thermalSensors = matching(0xff00, 5);
    CFArrayRef values = getThermalValues(thermalSensors);
    
    double atIndex36 = getValueByIndex(values, 36);

    CFRelease(values);
    
    return atIndex36;
}

double getRAMVoltage() {
    CFDictionaryRef voltageSensors = matching(0xff08, 3);
    CFArrayRef values = getPowerValues(voltageSensors);
    
    double atIndex1 = getValueByIndex(values, 1);

    CFRelease(values);
    
    return atIndex1 / 1000;
}

double getRAMCurrent() {
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    CFArrayRef values = getPowerValues(currentSensors);
    
    double atIndex25 = getValueByIndex(values, 25);

    CFRelease(values);
    
    return atIndex25 / 1000;
}
