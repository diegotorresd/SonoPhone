//
//  SonoViewController.m
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoViewController.h"
#import "SonoModel.h"

@interface SonoViewController ()

@property (nonatomic,strong) SonoModel * model;
@property (weak) NSTimer *SPLtimer;
-(void)getSPLfromModel:(NSTimer *)timer;

@end

@implementation SonoViewController

@synthesize SPLtimer = _SPLtimer;
@synthesize model = _model;

// model getter
-(SonoModel *)model
{
    // GETTER
    if (_model == nil)
    {
        NSLog(@"Initializing new model!");
        _model = [[SonoModel alloc] init];
    }
    return _model;
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getSPLfromModel:(NSTimer *)timer
{
    
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
