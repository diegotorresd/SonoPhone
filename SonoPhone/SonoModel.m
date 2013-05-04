//
//  SonoModel.m
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoModel.h"
#include "AverageBuffer.h"

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
    bool isMeasuring;
    Float32 SPLevel;
    enum SonoFreqWeighting freqWeighting;
    enum SonoTimeWeighting timeWeighting;
    //FilterStateBuffers timeWeightingFilterBuffers;
    FilterStateBuffers freqWeightingFilterBuffers[SONO_FREQWEIGHTING_NUMBUFFERS];
    AverageBuffer avgBuffer;
} SonoModelState;

@interface SonoModel ()
{
    SonoModelState state;
    Float64 sampleRate;
    
}
@property (nonatomic) SonoMeasurement * measurement;
-(bool)initializeFormat:(AudioStreamBasicDescription *)format;
-(UInt32)computeBufferByteSizeForFormat: (AudioStreamBasicDescription *)format Duration:(float)seconds;
@end

@implementation SonoModel

// static methods
static void InputBufferHandler(	void *								inUserData,
                               AudioQueueRef						inAQ,
                               AudioQueueBufferRef					inBuffer,
                               const AudioTimeStamp *				inStartTime,
                               UInt32								inNumPackets,
                               const AudioStreamPacketDescription*	inPacketDesc)
{
    SonoModelState * myState = (SonoModelState *)inUserData;
    OSStatus error;
    if (myState->isRunning)
    {
        myState->totalBytes += inNumPackets;
        NSLog(@"Reading %ld packets, already %ld read",inNumPackets,myState->totalBytes);
        AudioQueueLevelMeterState *meters;
        UInt32 sizeLvlMtr = sizeof(AudioQueueLevelMeterState) * myState->mFormat.mChannelsPerFrame;
        meters = malloc(sizeLvlMtr);
        error = AudioQueueGetProperty(inAQ, kAudioQueueProperty_CurrentLevelMeterDB, meters, &sizeLvlMtr);
        if (error) NSLog(@"Error getting level");
        else
        {
            //NSLog(@"Level: %g dB",meters[0].mAveragePower);
              myState->SPLevel = meters[0].mAveragePower;
        }
        free(meters);
        AudioSampleType *samples;
        if (myState->isMeasuring)
        {
            samples = (AudioSampleType *)inBuffer->mAudioData;
            float maxx = processSamples(samples,inBuffer->mAudioDataByteSize, myState);
            avgBufWrite(&myState->avgBuffer, &maxx);
        }
        //NSLog(@"RMS value: %g",maxx);
        error = AudioQueueEnqueueBuffer(myState->mQueue, inBuffer, 0, NULL);
        if (error) NSLog(@"Error enqueuing buffer");
    }
    else NSLog(@"Queue was stopped");
}

float processSamples(AudioSampleType * samples, UInt32 size, SonoModelState * s_state)
{
    //TODO: Revisar cálculos para integración
    int i;
    UInt32 numElements = size / sizeof(AudioSampleType);
    
    // Convert to floating point and deinterleave (take one every 2 samples)
    numElements = numElements / 2;
    float * vector = malloc(numElements * sizeof(float));
    vDSP_vflt16(samples, 2, vector, 1, numElements);
    
    // Freq Weighting Filter (3 biquad stages)
    if (s_state->freqWeighting != FreqWeightingFlat) {
        for (i=0;i<3;i++)
        {
            //NSLog(@"Processing stage %d",i);
            processWithIOData(vector, numElements, s_state->freqWeightingFilterBuffers[i]);
        }
    }
    
    // Square
    vsq(vector, 1, vector, 1, numElements);
    
    // Square root
    int n = (int)numElements;
    vvsqrtf(vector, vector, &n);
    
    // Normalize
    float maxval = 1 / s_state->freqWeightingFilterBuffers[0].gGainFactor;
    float * vec_normalized= malloc(numElements * sizeof(float));
    vDSP_vsdiv(vector, 1, &maxval, vec_normalized, 1, numElements);
    free(vector);
    
    // dB conversion
    float refValue = INT16_MAX; //TODO: Valor de calibración
    vDSP_vdbcon(vec_normalized, 1, &refValue, vec_normalized, 1, numElements, 1); // 20 log V_n/refValue
    
    // Get mean value
    float result = 0;
    vDSP_meanv(vec_normalized, 1, &result, numElements);
    free(vec_normalized);
    return result;
}

void processWithIOData(float * ioData,int frames, FilterStateBuffers BiQuadState)
{
    //Initialize buffers
    float * inputBuffer = malloc((frames + 2)*sizeof(float));
    float * outputBuffer = malloc((frames + 2)*sizeof(float));
    
    //Copy state
    memcpy(inputBuffer,BiQuadState.gInputKeepBuffer,2*sizeof(float));
    memcpy(outputBuffer,BiQuadState.gOutputKeepBuffer,2*sizeof(float));
    memcpy(&(inputBuffer[2]), ioData, frames*sizeof(float));
    
    //Filter
    vDSP_deq22(inputBuffer, 1, BiQuadState.gCoefBuffer, outputBuffer, 1, frames);
    memcpy(ioData, outputBuffer, frames*sizeof(float));
    memcpy(BiQuadState.gInputKeepBuffer, &(inputBuffer[frames]), 2*sizeof(float));
    memcpy(BiQuadState.gOutputKeepBuffer, &(outputBuffer[frames]), 2*sizeof(float));
    free(inputBuffer);
    free(outputBuffer);
}

// properties
@synthesize SPL = _SPL;
@synthesize isRunning;
@synthesize freqWeighting = _freqWeighting;
@synthesize timeWeighting = _timeWeighting;
@synthesize isMeasuring;
@synthesize integrationTime = _integrationTime;
@synthesize measurement = _measurement;

// isRunning getter:
-(BOOL)isRunning
{
    return state.isRunning;
}

// isMeasuring getter:
-(BOOL)isMeasuring
{
    return state.isMeasuring;
}

// SPL getter
-(float)SPL
{
    //NSLog(@"%g",state.SPLevel);
    return state.SPLevel;
}

// freqWeighting setter
-(void)setFreqWeighting:(enum SonoFreqWeighting)freqWeighting
{
    float AWeightCoefs1[] = {1.0000, -2.0000, 1.0000, -1.8849, 0.8864};
    float AWeightCoefs2[] = {1.0000,  2.0000, 1.0000, -1.9941, 0.9941};
    float AWeightCoefs3[] = {1.0000, -2.0000, 1.0000, -0.1405, 0.0049};
    float AWeightGainFactor = 0.2557;
    state.freqWeighting = freqWeighting;
    // set coefficients
    switch (freqWeighting)
    {
        case FreqWeightingA:
            // necesitamos 3 etapas
            state.freqWeightingFilterBuffers[0].gGainFactor = AWeightGainFactor;
            memcpy(state.freqWeightingFilterBuffers[0].gCoefBuffer, AWeightCoefs1, sizeof(AWeightCoefs1));
            memcpy(state.freqWeightingFilterBuffers[1].gCoefBuffer, AWeightCoefs2, sizeof(AWeightCoefs2));
            memcpy(state.freqWeightingFilterBuffers[2].gCoefBuffer, AWeightCoefs3, sizeof(AWeightCoefs3));
            break;
        case FreqWeightingC:
            //TODO: coeficientes
            break;
        case FreqWeightingI:
            //TODO: implementar?
            break;
        case FreqWeightingFlat:
            // do nothin'
            break;
    }
}

// freqWeighting getter
-(enum SonoFreqWeighting)freqWeighting
{
    return state.freqWeighting;
}

// measurement getter
-(SonoMeasurement *)measurement
{
    if (_measurement == nil)
        _measurement = [[SonoMeasurement alloc] init];
    return _measurement;
}

// initializer
-(id)init
{
    self = [super init];
    int i;
    if (self) {
        // Initialize filter states
        for (i=0;i<SONO_FREQWEIGHTING_NUMBUFFERS;i++)
        {
            state.freqWeightingFilterBuffers[i].gCoefBuffer = malloc(5*sizeof(float));
            state.freqWeightingFilterBuffers[i].gInputKeepBuffer = calloc(2,sizeof(float));
            state.freqWeightingFilterBuffers[i].gOutputKeepBuffer = calloc(2, sizeof(float));
        }
    }
    return self;
}

// destructor
- (void)dealloc
{
    int i;
    for (i=0;i<SONO_FREQWEIGHTING_NUMBUFFERS;i++)
    {
        free(state.freqWeightingFilterBuffers[i].gCoefBuffer);
        free(state.freqWeightingFilterBuffers[i].gInputKeepBuffer);
        free(state.freqWeightingFilterBuffers[i].gOutputKeepBuffer);
    }
}


// METHODS

-(void)startInput
{
    // check if queue was already running, in which case restart
    OSStatus error = 0;
    UInt32 queueIsRunning;
    UInt32 sizeProp = sizeof(queueIsRunning);
    error = AudioQueueGetProperty(state.mQueue, kAudioQueueProperty_IsRunning, &queueIsRunning, &sizeProp);
    if (queueIsRunning)
    {
        error = AudioQueueReset(state.mQueue);
        // allocate & enqueue buffers again
        [self allocateEnqueueBuffers:&error];
        if (error) NSLog(@"Error allocating/enqueuing buffers");
        else { state.isRunning = true; }
    }
    else
    {
        // Initialize format
        if (![self initializeFormat:&(state.mFormat)])
            NSLog(@"Error setting up format");
        // Set up Audio Queue
        error = AudioQueueNewInput(&(state.mFormat), InputBufferHandler, &state, NULL, NULL, 0, &(state.mQueue));
        if (error) NSLog(@"Error creating Audio Queue");
        else
        {
            // Get format back from AQ
            [self allocateEnqueueBuffers:&error];
            if (!error)
            {
                // Start Audio Queue
                error = AudioQueueStart(state.mQueue, NULL);
                if (error) NSLog(@"Error starting Audio Queue");
                else
                {
                    state.isRunning = true;
                    // Enable level metering
                    UInt32 meteringEnabled = 1;
                    error = AudioQueueSetProperty(state.mQueue, kAudioQueueProperty_EnableLevelMetering, &meteringEnabled, sizeof(meteringEnabled)  );
                    if (error) NSLog(@"Error enabling level metering");
                }
            }
        }
    } 
}

-(void)stopInput
{
    OSStatus error = 0;
    UInt32 queueIsRunning;
    UInt32 sizeProp = sizeof(queueIsRunning);
    error = AudioQueueGetProperty(state.mQueue, kAudioQueueProperty_IsRunning, &queueIsRunning, &sizeProp);
    if (queueIsRunning)
    {
        state.isRunning = false;
        // Stop Audio Queue
        error = AudioQueueStop(state.mQueue, true);
        if (error) NSLog(@"Error stopping queue");
        else
        {
            // Dispose Audio Queue
            error = AudioQueueDispose(state.mQueue, true);
            if (error) NSLog(@"Error disposing Audio Queue");
            // Stop Audio Session
            state.SPLevel = 0;
        }
    }
}

-(bool)initializeFormat:(AudioStreamBasicDescription *)format
{
    bool everythingAlright = false;
    UInt32 bitsperchannel = 16;
    if (!AudioSessionSetActive(true))
    {
        everythingAlright = true;
        //Float64 sampleRate;
        //NSLog(@"Sample rate: %g",sampleRate);
        UInt32 numChannels;
        UInt32 size = sizeof(numChannels);
        if (AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, &numChannels))
        {
            NSLog(@"Error getting num of channels");
            everythingAlright = false;
        }
        //NSLog(@"Num of channels: %ld",numChannels);
        if (everythingAlright)
        {
            //memset(&format, 0, sizeof(format));
            format->mFormatID = kAudioFormatLinearPCM;
            format->mSampleRate = sampleRate;
            format->mChannelsPerFrame = numChannels;
            format->mFormatFlags = kAudioFormatFlagsCanonical;
            format->mBytesPerFrame = numChannels * (bitsperchannel / 8);
            format->mBytesPerPacket = format->mBytesPerFrame;
            format->mFramesPerPacket = 1;
            format->mBitsPerChannel = 16;
            format->mReserved = 0;
        }
    }
    else NSLog(@"Error activating Audio Session");
    return everythingAlright;
}

-(UInt32)computeBufferByteSizeForFormat:(AudioStreamBasicDescription *)format Duration:(float)seconds
{
    int frames, bytes = 0;
    frames = (int)ceil(seconds * format->mSampleRate);
    bytes = frames * format->mBytesPerFrame;
    return bytes;
}

- (void)allocateEnqueueBuffers:(OSStatus *)error_p
{
    UInt32 sizeFormat = sizeof(AudioStreamBasicDescription);
    AudioQueueGetProperty(state.mQueue, kAudioQueueProperty_StreamDescription, &(state.mFormat), &sizeFormat);
    // Get size
    int i;
    // Allocate and enqueue buffers
    UInt32 bufSize = [self computeBufferByteSizeForFormat:&(state.mFormat)
                                                 Duration:Sono_BufferLengthSeconds];
    for (i=0;i<Sono_NumberOfBuffers;i++)
    {
        *error_p = AudioQueueAllocateBuffer(state.mQueue, bufSize, &(state.mBuffers[i]));
        if (*error_p)
        {
            NSLog(@"Error allocating buffer %d", i);
            break;
        }
        *error_p = AudioQueueEnqueueBuffer(state.mQueue, state.mBuffers[i], 0, NULL);
        if (*error_p)
        {
            NSLog(@"Error allocating buffer %d", i);
            break;
        }
    }
}

-(void)startMeasurement
{
    int size;
    size = (int)floorf(self.integrationTime / Sono_BufferLengthSeconds);
    NSLog(@"size: %d",size);
    // init measurement
    self.measurement.description = @"Sample measurement"; //TODO: from user input?
    self.measurement.startDate = [NSDate date];
    state.isMeasuring = true;
    // calculate size
    avgBufInit(&state.avgBuffer, size);
}

-(void)stopMeasurement
{
    self.measurement.endDate = [NSDate date];
    state.isMeasuring = false;
    avgBufRelease(&state.avgBuffer);
}

-(void)calibrate
{
    
}
@end
