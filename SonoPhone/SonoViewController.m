//
//  SonoViewController.m
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoViewController.h"
#import "SonoModel.h"

#define Sono_MinDBValue -60.0

@interface SonoViewController () <SonoLevelMeterDataSource>
@property (weak, nonatomic) IBOutlet SonoLevelMeter *SPLMeter;

@property (nonatomic,strong) SonoModel * model;
@property (weak) NSTimer *SPLtimer;
-(void)getSPLfromModel:(NSTimer *)timer;

@end

@implementation SonoViewController

@synthesize SPLtimer = _SPLtimer;
@synthesize model = _model;
@synthesize startStopSwitch = _startStopSwitch;
@synthesize FreqWeightingControl = _FreqWeightingControl;
@synthesize SPLMeter = _SPLMeter;

// model getter
-(SonoModel *)model
{
    // GETTER
    if (_model == nil)
    {
        //NSLog(@"Initializing new model!");
        _model = [[SonoModel alloc] init];
    }
    return _model;
}

-(void)setSPLMeter:(SonoLevelMeter *)SPLMeter
{
    _SPLMeter = SPLMeter;
    self.SPLMeter.dataSource = self;
    self.SPLMeter.meterColor = [[UIColor alloc] initWithRed:0.0 green:0.2 blue:1.0 alpha:0.9];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Initialize Audio Session
    OSStatus error = 0;
    error = AudioSessionInitialize(NULL, NULL, interruptionListener, (__bridge void *)(self));
    if (error) NSLog(@"Error initializing AudioSession");
    else
    {
        // Set Category: Record
        UInt32 category = kAudioSessionCategory_RecordAudio;
        error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
        if (error) NSLog(@"Error setting Category");
        
        // Checking input availability
        UInt32 inputAvailable = 0;
        UInt32 size = sizeof(inputAvailable);
        error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
        if (error) NSLog(@"Error getting input availability");
        NSLog(@"Input availability: %ld",inputAvailable);
    }
    [self.startStopSwitch setOn:self.model.isRunning];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getSPLfromModel:(NSTimer *)timer
{
    //NSLog(@"Bump!");
    [self.SPLMeter setNeedsDisplay];
}

#pragma mark Actions

- (IBAction)inputStartStop:(id)sender forEvent:(UIEvent *)event {
    UISwitch * inputSwitch = (UISwitch *)sender;
    if (inputSwitch.on)
    {
        //start input
        [self.model startInput];
        if (self.SPLtimer)
            [self.SPLtimer invalidate];
        self.SPLtimer = [NSTimer timerWithTimeInterval:Sono_SPLRefreshInterval
                                                target:self
                                              selector:@selector(getSPLfromModel:)
                                              userInfo:nil
                                               repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.SPLtimer forMode:NSDefaultRunLoopMode];
        
    }
    else
    {
        //stop input
        [self.model stopInput];
        if ([self.SPLtimer isValid]) [self.SPLtimer invalidate];
    }
}

- (IBAction)freqWeightingSelected:(id)sender {
    switch ([sender selectedSegmentIndex]) {
        case 0: // A
            self.model.freqWeighting = FreqWeightingA;
            break;
        case 1:
            self.model.freqWeighting = FreqWeightingC;
            break;
        case 2:
            self.model.freqWeighting = FreqWeightingFlat;
            break;
        default:
            break;
    }
}

#pragma mark SonoLevelMeterDataSource
-(float)SPLValueForLevelMeter:(SonoLevelMeter *)meter
{
    float val = 0;
    float relVal = Sono_MinDBValue;
    if (self.model.isRunning)
    {
        val = self.model.SPL - relVal;
        val = val / abs(relVal);
        if (val < 0) val = 0;
        if (val > 1) val = 1;
    }
    else val = 0;
    //NSLog(@"norm value: %f (re %f)", val, relVal);
    return val;
}

#pragma mark Interruption Listener
void interruptionListener(void * inClientData, UInt32 interruptionState)
{
    SonoViewController *THIS = (__bridge SonoViewController *)inClientData;
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        if (THIS.model.isRunning)
            [THIS.model stopInput];
    }
}

@end
