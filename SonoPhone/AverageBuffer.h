//
//  AverageBuffer.h
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#ifndef SonoPhone_AverageBuffer_h
#define SonoPhone_AverageBuffer_h

typedef struct
{
    int size;
    int end;
    float * avgElems;
    float totalAvg;
} AverageBuffer;

void avgBufInit(AverageBuffer * buf, int size);

void avgBufWrite(AverageBuffer * buf, float * newElem);

void avgBufRelease(AverageBuffer * buf);

float calculateAverage(AverageBuffer * buf);

#endif
