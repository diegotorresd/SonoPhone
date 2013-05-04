//
//  AverageBuffer.c
//  SonoPhone
//
//  Created by Diego Torres on 24/04/13.
//  Copyright (c) 2013 Diego Torres. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "AverageBuffer.h"

float calculateAverage(AverageBuffer * buf);

void avgBufInit(AverageBuffer * buf, int size)
{
    buf->size = size;
    buf->end = 0;
    buf->totalAvg = 0;
    buf->avgElems = calloc(buf->size, sizeof(float));
}

void avgBufWrite(AverageBuffer * buf, float * newElem)
{
    buf->avgElems[buf->end] = *newElem;
    buf->totalAvg = calculateAverage(buf);
    buf->end = (buf->end + 1) % buf->size;
}

float calculateAverage(AverageBuffer * buf)
{
    int i;
    float sum = 0.0;
    for (i=0; i<buf->size; i++)
    {
        sum += buf->avgElems[i];
    }
    return sum / buf->size;
}

void avgBufRelease(AverageBuffer * buf)
{
    free(buf->avgElems);
}