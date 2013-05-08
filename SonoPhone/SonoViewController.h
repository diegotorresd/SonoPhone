//
//  SonoViewController.h
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SonoLevelMeter.h"
#define Sono_SPLRefreshInterval 0.125

@interface SonoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *FreqWeightingControl;
@property (weak, nonatomic) IBOutlet UISwitch *startStopSwitch;


@end
