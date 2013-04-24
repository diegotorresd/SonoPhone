//
//  SonoModel.h
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioSession.h>
#import <Accelerate/Accelerate.h>

#define Sono_NumberOfBuffers 3
#define Sono_BufferLengthSeconds 0.25
#define Sono_SlowTimeConstant 1
#define Sono_FastTimeConstant 0.125

@interface SonoModel : NSObject

// STATE
@property (nonatomic, readonly) BOOL isRunning;

// DATA
@property (nonatomic) float SPL;

// METADATA
enum SonoTimeWeighting { TimeWeightingFast, TimeWeightingSlow };
enum SonoFreqWeighting { FreqWeightingA, FreqWeightingC, FreqWeightingI, FreqWeightingFlat };

@property (nonatomic) enum SonoTimeWeighting timeWeighting;
@property (nonatomic) enum SonoFreqWeighting freqWeighting;

// METHODS
- (void)startInput;
- (void)stopInput;

@end

