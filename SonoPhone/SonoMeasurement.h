//
//  SonoMeasurement.h
//  SonoPhone
//
//  Created by Diego Torres on 02/05/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SonoMeasurement : NSObject

@property NSString * description;
@property NSDate * startDate;
@property NSDate * endDate;
@property (nonatomic) NSNumber * measurementLength;
@property (nonatomic) NSDictionary * data;
//@property CFDictionaryRef dataRef;
@property (nonatomic) NSDictionary * timeWeightedData;
@property (readonly) NSNumber * EquivalentLevelDB;
@property (readonly) NSNumber * PeakValueDB;

-(NSString *)persistMeasurement;
-(BOOL)loadMeasurementFromFile:(NSString *)filePath;


@end
