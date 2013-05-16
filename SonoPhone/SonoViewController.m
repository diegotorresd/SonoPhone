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

@interface SonoViewController () <SonoLevelMeterDataSource, SonoModelDelegate>
@property (weak, nonatomic) IBOutlet SonoLevelMeter *SPLMeter;
@property (weak, nonatomic) IBOutlet UIButton *StoreStopButton;
@property (nonatomic) BOOL measuring;
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
@synthesize measuring;

// model getter
-(SonoModel *)model
{
    // GETTER
    if (_model == nil)
    {
        //NSLog(@"Initializing new model!");
        _model = [SonoModel sharedSonoModel];
    }
    return _model;
}

// model setter
-(void)setModel:(SonoModel *)model
{
    _model = model;
}

// measuring getter
-(BOOL)measuring
{
    return self.model.isMeasuring;
}

-(void)setSPLMeter:(SonoLevelMeter *)SPLMeter
{
    _SPLMeter = SPLMeter;
    self.SPLMeter.dataSource = self;
    self.SPLMeter.meterColor = [[UIColor alloc] initWithRed:0.0 green:0.2 blue:1.0 alpha:0.9];
}

- (void)viewDidLoad
{
    NSLog(@"Loading SonoViewController");
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
    //UIColor * greenColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.8];
    //[self.StoreStopButton setTintColor:greenColor];
    [self.StoreStopButton setEnabled:NO];
    self.model.delegate = self;
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GoToCalibration"])
    {
        if (self.model.isRunning)
            [self.model stopInput];
        self.model.calibrationDelegate = segue.destinationViewController;
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"GoToCalibration"] && !self.model.isMeasuring) {
        return YES;
    }
    else return NO;
}

#pragma mark Actions

- (IBAction)inputStartStop:(id)sender forEvent:(UIEvent *)event {
    UISwitch * inputSwitch = (UISwitch *)sender;
    if (inputSwitch.on)
    {
        self.model.freqWeighting = FreqWeightingA;
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
        [self.SPLMeter setNeedsDisplay];
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
- (IBAction)StoreStopTouched:(id)sender {
    if (!self.measuring)
    {
        
        [self.model startMeasurement];
    }
    else
    {
        NSLog(@"stopping measurement");
        [self.model stopMeasurement];
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

#pragma mark SonoModelDelegate
-(void)measurementWasStarted
{
    //NSLog(@"delegate msg received: start");
    [self.StoreStopButton setTitle:@"STOP" forState:UIControlStateNormal];
    // disable controls
    [self.startStopSwitch setEnabled:NO];
    [self.FreqWeightingControl setEnabled:NO];
}

-(void)measurementWasStopped
{
    //UIColor * greenColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.8];
    [self.StoreStopButton setTitle:@"STORE" forState:UIControlStateNormal];
    //[self.StoreStopButton setTintColor:greenColor];
    // enable controls
    [self.startStopSwitch setEnabled:YES];
    [self.FreqWeightingControl setEnabled:YES];

}

-(void)inputWasStarted
{
    // enable measurement button
    [self.StoreStopButton setEnabled:YES];
    [self.startStopSwitch setOn:YES];
}

-(void)inputWasStopped
{
    // disable measurement button
    [self.StoreStopButton setEnabled:NO];
    [self.startStopSwitch setOn:NO];
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
