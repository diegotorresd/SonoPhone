//
//  SonoMeasurement.m
//  SonoPhone
//
//  Created by Diego Torres on 02/05/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import "SonoMeasurement.h"
#import <CoreLocation/CoreLocation.h>

#define Sono_Location_DesiredAccuracyMeters 100
#define Sono_Location_DesiredFreshnessSeconds 10

@interface SonoMeasurement () <CLLocationManagerDelegate>

@property (nonatomic) NSDictionary * dictToPersist;
@property (nonatomic) CLLocation * location;
@property (nonatomic) CLLocationManager * locManager;
@end

@implementation SonoMeasurement

@synthesize description = _description;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize data = _data;
@synthesize timeWeightedData = _timeWeightedData;
@synthesize measurementLength = _measurementLength;
@synthesize EquivalentLevelDB = _EquivalentLevelDB;
@synthesize PeakValueDB;
@synthesize dictToPersist = _dictToPersist;
@synthesize locManager = _locManager;
@synthesize location = _location;

-(id)init
{
    [self.locManager setDelegate:self];
    return self;
}

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

-(NSNumber *)measurementLength
{
    _measurementLength = [NSNumber numberWithDouble:[self.endDate timeIntervalSinceDate:self.startDate]];
    return _measurementLength;
}

-(CLLocationManager *)locManager
{
    if (![CLLocationManager locationServicesEnabled])
        return nil;
    if (_locManager == nil)
    {
        _locManager = [[CLLocationManager alloc] init];
        _locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        [_locManager startUpdatingLocation];
    }
    return _locManager;
}

-(NSNumber *)EquivalentLevelDB
{
    if (self.data.count > 0)
    {
        float result = 0;
        float sum = 0;
        NSEnumerator *en = [self.data objectEnumerator];
        id val;
        while (val = [en nextObject])
        {
            NSNumber * num = (NSNumber *)val;
            sum += num.floatValue;
        }
        //NSLog(@"SUM: %f",sum);
        sum = sum / self.measurementLength.doubleValue;
        result = log10f(sqrtf(sum));
        float calibrationValue = [[NSUserDefaults standardUserDefaults] floatForKey:@"CalibrationValuedB"];
        _EquivalentLevelDB = [NSDecimalNumber numberWithFloat:(result + calibrationValue)];
    }
    else
        _EquivalentLevelDB = 0;
    return _EquivalentLevelDB;
}

-(NSDictionary *)dictToPersist
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSDictionary * locationDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithDouble:self.location.coordinate.latitude], @"Latitude",
                                   [NSNumber numberWithDouble:self.location.coordinate.longitude], @"Longitude",
                                   [NSNumber numberWithDouble:self.location.altitude], @"Altitude", nil];
    _dictToPersist = [NSDictionary dictionaryWithObjectsAndKeys:
                      self.description,@"Description",
                      [dateFormatter stringFromDate: self.startDate],@"startDate",
                      locationDict,@"Location",
                      [dateFormatter stringFromDate: self.endDate],@"endDate",
                      self.measurementLength,@"measurementLength",
                      self.EquivalentLevelDB,@"EquivalentValueDB",
                      self.data,@"Data",
                      nil];
    return _dictToPersist;
}

-(NSString *)persistMeasurement
{
    NSError * creationError;
    //CFURLRef fileURL;
    //CFDataRef fileData;
    BOOL success;
    //long errorCode;
    //CFShow(self.dataRef);
    //TODO: Directorio? Nombre de fich como parametro?
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * fileName = [NSString stringWithFormat:@"measurement%@.xml", [dateFormatter stringFromDate:self.startDate]];
    NSString * filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    NSLog(@"fileName: %@",filePath);
    
    // CoreFoundation method
//    fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)(filePath), kCFURLPOSIXPathStyle, false);
//    fileData = CFPropertyListCreateData(kCFAllocatorDefault, self.dataRef, kCFPropertyListXMLFormat_v1_0,0,NULL);
//    success = CFURLWriteDataAndPropertiesToResource(fileURL, fileData, NULL, &errorCode);
//    CFRelease(fileURL);
//    CFRelease(fileData);
    
    // Cocoa method
    NSData * serializedData = [NSPropertyListSerialization dataWithPropertyList:self.dictToPersist format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:&creationError];
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:self.dictToPersist options:NSJSONWritingPrettyPrinted error:&creationError];
    //TODO: Handle errors
    success = [serializedData writeToFile:filePath atomically:YES];
    if (!success) NSLog(@"Error writing");
    success = [jsonData writeToFile:[filePath stringByAppendingPathExtension:@"json"] atomically:YES];
    return filePath.lastPathComponent;
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

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation * firstLoc = [locations objectAtIndex:0];
    NSLog(@"location: %@",firstLoc);
    // check if location is recent and accurate
    NSTimeInterval freshness = [[firstLoc timestamp] timeIntervalSinceNow];
    CLLocationAccuracy accuracy = [firstLoc horizontalAccuracy];
    if (freshness <= Sono_Location_DesiredFreshnessSeconds &&
        accuracy <= Sono_Location_DesiredAccuracyMeters)
    {
        NSLog(@"chosen location: %@",firstLoc);
        self.location = firstLoc;
        [manager stopUpdatingLocation];
    }
}

@end
