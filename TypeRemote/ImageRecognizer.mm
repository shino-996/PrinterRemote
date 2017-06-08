//
//  ImageRecognizer.m
//  TypeRemote
//
//  Created by shino on 2017/6/8.
//  Copyright © 2017年 shino. All rights reserved.
//

#import "ImageRecognizer.h"

@implementation ImageRecognizer

int LengthOf(TPoint p1, TPoint p2) {
    return (int)sqrt(pow(float(p1.x - p2.x), 2) + pow(float(p1.y - p2.y), 2));
}

inline Pixel Gray(int R, int G, int B) {
//灰度化程序，根据:简化 sRGB IEC61966-2.1 [gamma=2.20]
    return pow((pow(R, 2.2)*0.2126 + pow(G, 2.2)*0.7152 + pow(B, 2.2)*0.0722), (1 / 2.2));
}

- (void) getMatrix:(NSMutableArray*)imageArray WithWidth:(int)width AndHeight:(int)height {
    mat = (PixelMatrix*)malloc(sizeof(PixelMatrix));
    mat->height = height;
    mat->width = width;
    Pixel **data;
    data = (Pixel**)malloc(sizeof(Pixel*) * height);
    for (int i = 0; i < height; i++) {
        data[i] = (Pixel*)malloc(sizeof(Pixel) * width);
    }
    mat->data = data;
    for(int h = 0; h < height; ++h) {
        for(int w = 0; w < width; ++w) {
            int RPixel = [imageArray[(width * h + w) * 3] intValue];
            int GPixel = [imageArray[(width * h + w) * 3 + 1] intValue];
            int BPixel = [imageArray[(width * h + w) * 3 + 2] intValue];
//            *(*(data + h) + w) = (RPixel + GPixel + BPixel) / 3;
            int grayPixel = Gray(RPixel, GPixel, BPixel);
            printf("%d, ", grayPixel);
            *(*(data + h) + w) = Gray(RPixel, GPixel, BPixel);
            //            printf("(%d, %d, %d) ", RPixel, GPixel, BPixel);
//            printf("%d, ", (RPixel + GPixel + BPixel) / 3);
        }
        printf("\n");
    }
    //    for(int h = 0; h < height; ++h) {
    //        for(int w = 0; w < width; ++w) {
    //            printf("%d, ", *(*(data + h) + w));
    //        }
    //        printf("\n");
    //    }
}

- (void)ThinImage {
    int i, j;
    Pixel** data2;
    unsigned char mask = 150;
    for (i = 0; i < mat->height; i++) {
        for (j = 0; j < mat->width; j++) {
            if (mat->data[i][j] < mask) {
                mat->data[i][j] = 255;
//                printf("*");
            } else {
                mat->data[i][j] = 0;
//                printf(" ");
            }
        }
//        printf("\n");
    }
    
    //拷贝一个备份
    data2 = (Pixel**)malloc(sizeof(Pixel*) * mat->height);
    for (i = 0; i < mat->height; i++) {
        data2[i] = (Pixel*)malloc(sizeof(Pixel) * mat->width);
    }
    for (i = 0; i < mat->height; i++) {
        for (j = 0; j < mat->width; j++) {
            data2[i][j] = mat->data[i][j];
        }
    }
    
    //进行细化
    //扫描每个像素
    for (i = 0; i < mat->height; i++) {
        for (j = 0; j < mat->width; j++) {
            // 如果当前像素是有颜色的
            if (mat->data[i][j] == 255) {
                // 而且还是个边缘像素
                if (mat->data[i + 1][j] == 0 ||
                    mat->data[i - 1][j] == 0 ||
                    mat->data[i][j + 1] == 0 ||
                    mat->data[i][j - 1] == 0 ||
                    mat->data[i + 1][j + 1] == 0 ||
                    mat->data[i - 1][j - 1] == 0 ||
                    mat->data[i - 1][j + 1] == 0 ||
                    mat->data[i + 1][j - 1] == 0) {
                    // 如果这里已经很细了就算了
                    if (((mat->data[i + 1][j] != 255) && (mat->data[i - 1][j] != 255)) +
                        ((mat->data[i][j + 1] != 255) && (mat->data[i][j - 1] != 255)) +
                        ((mat->data[i + 1][j + 1] != 255) && (mat->data[i - 1][j - 1] != 255)) +
                        ((mat->data[i + 1][j - 1] != 255) && (mat->data[i - 1][j + 1] != 255)) >= 3) {
                        ;
                    } else {
                        //那就把它去除吧
                        //mat->data[i][j] = 1;
                        mat->data[i][j] = 0;
                    }
                }
            }
        }
    }
    
    //上面的过程好像横向的还保留得不错但是纵向的就全没了所以我们再来一遍。。。
    for (j = 0; j < mat->width; j++) {
        for (i = 0; i < mat->height; i++) {
            if (data2[i][j] == 255)
            {
                if (data2[i + 1][j] == 0 ||
                    data2[i - 1][j] == 0 ||
                    data2[i][j + 1] == 0 ||
                    data2[i][j - 1] == 0 ||
                    data2[i + 1][j + 1] == 0 ||
                    data2[i - 1][j - 1] == 0 ||
                    data2[i - 1][j + 1] == 0 ||
                    data2[i + 1][j - 1] == 0) {
                    if (((data2[i + 1][j] != 255) && (data2[i - 1][j] != 255)) +
                        ((data2[i][j + 1] != 255) && (data2[i][j - 1] != 255)) +
                        ((data2[i + 1][j + 1] != 255) && (data2[i - 1][j - 1] != 255)) +
                        ((data2[i + 1][j - 1] != 255) && (data2[i - 1][j + 1] != 255)) >= 3) {
                        ;
                    } else {
                        data2[i][j] = 0;
                    }
                }
            }
        }
    }
    
    //合并两次结果
    for (i = 0; i < mat->height; i++) {
        for (j = 0; j < mat->width; j++) {
            mat->data[i][j] = mat->data[i][j] > data2[i][j] ? mat->data[i][j] : data2[i][j];
        }
    }
    
    for (i = 0; i < mat->height; i++) {
        free(data2[i]);
    }
    free(data2);
    
//    printf("细化结果\n");
//    for (i = 0; i < mat->height; i++) {
//        for (j = 0; j < mat->width; j++) {
//            if (mat->data[i][j] != 0) {
//                printf("*");
//            } else {
//                printf(" ");
//            }
//        }
//        printf("\n");
//    }
}

- (void)findKeyPoint {
    int i, j, a, b, tmpc;
    //采样区间中的关键点
    countOfPoints = 0;
    int interval = 5;
    TPoint keypoint;
    points = (TPoint*)malloc(sizeof(TPoint));
    
    //    Log("采样\n");
    for (i = 0; i < (mat->height - 1) / interval; i++) {
        for (j = 0; j < (mat->width - 1) / interval; j++) {
            // 每一个采样区间
            tmpc = 0;
            keypoint.x = 0;
            keypoint.y = 0;
            for (a = i*interval; a < (i + 1)*interval; a++){
                for (b = j*interval; b < (j + 1)*interval; b++) {
                    if (mat->data[a][b] > 0) {
                        tmpc++;
                        keypoint.x += b;
                        keypoint.y += a;
                    }
                }
            }
            if (tmpc) {
                //存在关键点
                keypoint.x = keypoint.x / tmpc;
                keypoint.y = keypoint.y / tmpc;
                (countOfPoints)++;
                points = (TPoint*)realloc(points, sizeof(TPoint)*(countOfPoints));
                points[countOfPoints - 1].x = keypoint.x;
                points[countOfPoints - 1].y = keypoint.y;
            }
        }
    }
}

- (NSArray*)getStrokes {
    int interval = 5;
    Stroke* strokes = (Stroke*)malloc(sizeof(Stroke));
    Stroke stroke;
    int countOfCheckedPoint = 0;
    countOfStrokes = 0;
    int i, j;
    int nearP, tmpnear;
    int indexCurrent = 0;
    int tmpindex;
    int flag;
    
    while (countOfCheckedPoint < countOfPoints) {
        // 找一个起点
        nearP = 100;//离这个点很近的点的个数
        for (i = 0; i < countOfPoints; i++) {
            if (points[i].x != -1) {
                // 离计算这个点很近的点的个数
                tmpnear = 0;
                for (j = 0; j < countOfPoints; j++) {
                    if (points[j].x != -1 && j!=i) {
                        if (LengthOf(points[i], points[j]) < 4 * interval) {
                            tmpnear++;
                        }
                    }
                }
                // 如果这个点附近的点很少说明它可能是一个起点
                if (tmpnear < nearP) {
                    indexCurrent = i;
                    nearP = tmpnear;
                }
            }
        }
        // 找到一个新起点，生成笔画
        countOfStrokes++;
        strokes = (Stroke*)realloc(strokes, sizeof(Stroke)*(countOfStrokes));
        stroke.length = 1;
        stroke.data = (TPoint*)malloc(sizeof(TPoint));
        stroke.data[0].x = points[indexCurrent].x;
        stroke.data[0].y = points[indexCurrent].y;
        countOfCheckedPoint++;
        points[indexCurrent].x = -1;//屏蔽掉已经用过的点
        tmpindex = 0;
        flag = 1;
        while (flag) {
            //最近的点的距离
            tmpnear = 1000;
            for (i = 0; i < countOfPoints; i++) {
                if (points[i].x != -1 && i!=indexCurrent) {
                    int t = LengthOf(stroke.data[stroke.length-1], points[i]);
                    if (t < tmpnear) {
                        tmpnear = t;
                        tmpindex = i;
                    }
                }
            }
            // 找到最近的点
            if (tmpnear < 4 * interval) {
                //连起来
                indexCurrent = tmpindex;
                stroke.length++;
                stroke.data = (TPoint*)realloc(stroke.data, sizeof(TPoint)*stroke.length);
                stroke.data[stroke.length - 1].x = points[indexCurrent].x;
                stroke.data[stroke.length - 1].y = points[indexCurrent].y;
                countOfCheckedPoint++;
                points[indexCurrent].x = -1;//屏蔽掉已经用过的点
            } else {
                //已经连完一条线了
                strokes[countOfStrokes - 1] = stroke;
                flag = false;
            }
        }
    }
    NSMutableArray* strokeArray = [[NSMutableArray alloc] init];
    for(int i = 0; i < countOfStrokes; ++i) {
        NSMutableArray* pointArray = [[NSMutableArray alloc] init];
        for(int j = 0; j < strokes[i].length; ++j) {
            NSString* str = [[NSString alloc] initWithFormat:@"%04d %04d 9", strokes[i].data[j].x, strokes[i].data[j].y];
            [pointArray addObject:str];
            if(j == strokes[i].length - 1) {
                NSString* endStr = [[NSString alloc] initWithFormat:@"%04d %04d 0", strokes[i].data[j].x, strokes[i].data[j].y];
                [pointArray addObject:endStr];
            }
//            printf("{%d, %d}, ", strokes[i].data[j].x, strokes[i].data[j].y);
        }
//        printf("\n");
        [strokeArray addObject:pointArray];
    }
    return [strokeArray copy];
}

@end
