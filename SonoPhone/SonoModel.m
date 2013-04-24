//
//  SonoModel.m
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoModel.h"
#include "AverageBuffer.h"

@interface SonoModel ()

// private members
#define SONO_FREQWEIGHTING_NUMBUFFERS 3
typedef struct
{
    float * gCoefBuffer;
    float * gInputKeepBuffer;
    float * gOutputKeepBuffer;
    float gGainFactor;
} FilterStateBuffers;

typedef struct
{
    AudioStreamBasicDescription mFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[Sono_NumberOfBuffers];
    UInt32 totalBytes;
    bool isRunning;
    Float32 SPLevel;
    enum SonoFreqWeighting freqWeighting;
    enum SonoTimeWeighting timeWeighting;
    FilterStateBuffers timeWeightingFilterBuffers;
    FilterStateBuffers freqWeightingFilterBuffers[SONO_FREQWEIGHTING_NUMBUFFERS];
} SonoModelState;

@end

@implementation SonoModel

@synthesize SPL = _SPL;
@synthesize isRunning;
@synthesize freqWeighting = _freqWeighting;
@synthesize timeWeighting = _timeWeighting;

-(void)startInput
{
    
}

-(void)stopInput
{
    
}
@end
