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

-(id)data
{
    if (_data == nil)
        _data = [NSDictionary dictionary];
    return _data;
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
