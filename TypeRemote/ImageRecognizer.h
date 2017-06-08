//
//  ImageRecognizer.h
//  TypeRemote
//
//  Created by shino on 2017/6/8.
//  Copyright © 2017年 shino. All rights reserved.
//

#ifndef ImageRecognizer_h
#define ImageRecognizer_h

#import <Foundation/Foundation.h>

typedef unsigned char Pixel;

typedef struct PixelMatrix {
    int width;
    int height;
    Pixel** data;
} PixelMatrix;

typedef struct TPoint {
    int x;
    int y;
} TPoint;

typedef struct Stroke {
    struct TPoint* data;
    int length;
} Stroke;

@interface ImageRecognizer : NSObject {
    
    PixelMatrix* mat;
    TPoint* points;
    int countOfPoints;
    int countOfStrokes;
    
}

- (void)getMatrix:(NSMutableArray*)imageArray WithWidth:(int)width AndHeight:(int)height;

- (void)findKeyPoint;

- (void)ThinImage;

- (NSArray*)getStrokes;

@end


#endif /* ImageRecognizer_h */
