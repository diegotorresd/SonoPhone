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
#import "SonoMeasurement.h"

#define Sono_NumberOfBuffers 3
#define Sono_BufferLengthSeconds 0.125
#define Sono_SlowTimeConstant 1
#define Sono_FastTimeConstant 0.125

@protocol SonoModelDelegate <NSObject>
-(void)measurementWasStarted;
-(void)measurementWasStopped;
-(void)inputWasStarted;
-(void)inputWasStopped;
@end

@interface SonoModel : NSObject

// STATE
@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, readonly) BOOL isMeasuring;

// DATA
@property (nonatomic) float SPL;

// METADATA
enum SonoTimeWeighting { TimeWeightingFast, TimeWeightingSlow };
enum SonoFreqWeighting { FreqWeightingA, FreqWeightingC, FreqWeightingI, FreqWeightingFlat };

@property (nonatomic) enum SonoTimeWeighting timeWeighting;
@property (nonatomic) enum SonoFreqWeighting freqWeighting;
//@property (nonatomic) float integrationTime; // seconds

// DELEGATE
@property (nonatomic, weak) id<SonoModelDelegate> delegate;

// METHODS
- (void)startInput;
- (void)stopInput;
- (void)startMeasurement;
- (void)stopMeasurement;
- (void)calibrate;

@end


