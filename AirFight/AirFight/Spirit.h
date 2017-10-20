//
//  Spirit.h
//  AirFight
//
//  Created by 马异峰 on 2017/10/20.
//  Copyright © 2017年 Yifeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Spirit : NSObject

@property(nonatomic,strong)CALayer *layer;
@property(nonatomic,assign)NSInteger imageIndex;
-(id)initWithLayer:(CALayer*)layer imageIndex:(NSInteger)imageIndex;

@end
