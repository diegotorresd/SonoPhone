

#import <UIKit/UIKit.h>

@class SonoLevelMeter;

@protocol SonoLevelMeterDataSource <NSObject>

-(float)SPLValueForLevelMeter:(SonoLevelMeter *)meter;

@end

@interface SonoLevelMeter : UIView
@property (nonatomic,weak) IBOutlet id <SonoLevelMeterDataSource> dataSource;
@property UIColor * meterColor;
@end

