//
//  Spirit.m
//  AirFight
//
//  Created by 马异峰 on 2017/10/20.
//  Copyright © 2017年 Yifeng. All rights reserved.
//

#import "Spirit.h"

@implementation Spirit
-(id)initWithLayer:(CALayer *)layer imageIndex:(NSInteger)imageIndex{
    if ((self = [super init]) != nil) {
        _layer = layer;
        _imageIndex = imageIndex;
    }
    return self;
}

@end
