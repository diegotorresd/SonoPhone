//
//  SonoCalibrationViewController.m
//  SonoPhone
//
//  Created by Diego Torres on 14/05/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoCalibrationViewController.h"
#import "SonoModel.h"

@interface SonoCalibrationViewController () <SonoModelCalibrationDelegate>
@property (weak, nonatomic) IBOutlet UILabel *CalibrationStatus;
@property (nonatomic,weak) SonoModel *model;
@end

@implementation SonoCalibrationViewController

@synthesize model = _model;

- (IBAction)calibrateButtonPressed:(id)sender {
    [self.model calibrate];
}

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark SonoModelCalibrationDelegate

-(void)calibrationWasStarted
{
    self.CalibrationStatus.text = @"Calibrating...";
}

-(void)calibrationWasFinished
{
    self.CalibrationStatus.text = @"Calibration finished";
}

@end
