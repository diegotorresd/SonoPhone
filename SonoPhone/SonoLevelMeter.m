#import "SonoLevelMeter.h"

@implementation SonoLevelMeter

@synthesize dataSource = _dataSource;
@synthesize meterColor;

- (void)setup
{
    self.contentMode = UIViewContentModeRedraw;
}

- (void)awakeFromNib
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextAddRect
    [meterColor set];
    CGRect leRect = CGRectMake(0, 0,
                               self.bounds.size.width * [self.dataSource SPLValueForLevelMeter:self],
                               self.bounds.size.height);
    CGContextFillRect(context, leRect);
}

@end

