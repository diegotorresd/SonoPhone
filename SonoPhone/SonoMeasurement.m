//
//  SonoMeasurement.m
//  SonoPhone
//
//  Created by Diego Torres on 02/05/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoMeasurement.h"

@implementation SonoMeasurement

@synthesize description = _description;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize data = _data;
@synthesize timeWeightedData = _timeWeightedData;
@synthesize measurementLength = _measurementLength;
@synthesize EquivalentLevelDB;
@synthesize PeakValueDB;

-(id)data
{
    if (_data == nil)
        _data = [NSDictionary dictionary];
    return _data;
}

-(NSDictionary *)timeWeightedData
{
    if (_timeWeightedData == nil)
        _timeWeightedData = [NSDictionary dictionary];
    return _timeWeightedData;
}

-(NSTimeInterval)measurementLength
{
    NSTimeInterval interval = [self.endDate timeIntervalSinceDate:self.startDate];
    return interval;
}

-(float)EquivalentLevelDB
{
    if (self.data.count > 0)
    {
        float result = 0;
        float sum = 0;
        NSEnumerator *en = [self.data objectEnumerator];
        id val;
        while (val = [en nextObject])
        {
            // val == NSCFNumber
            NSNumber * num = (NSNumber *)val;
            sum += num.floatValue;
        }
        NSLog(@"SUM: %f",sum);
        sum = sum / self.measurementLength;
        result = log10f(sqrtf(sum));
        float calibrationValue = [[NSUserDefaults standardUserDefaults] floatForKey:@"CalibrationValuedB"];
        return result + calibrationValue;
    }
    else
        return 0;
}

-(NSString *)persistMeasurement
{
    //TODO: Directorio? Nombre de fich como parametro?
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSString * fileName = [@"Measurement" stringByAppendingString:[dateFormatter stringFromDate:self.startDate]];
    NSString * recordFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSData * serializedData = [NSPropertyListSerialization dataFromPropertyList:self.data format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    //TODO: Handle errors
    [serializedData writeToFile:recordFile atomically:YES];
    return recordFile;
}

-(BOOL)loadMeasurementFromFile:(NSString *)filePath
{
    BOOL result = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData * pListData = [NSData dataWithContentsOfFile:filePath];
        self.data = [NSPropertyListSerialization propertyListFromData:pListData mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:nil];
    }
    return result;
}

@end
