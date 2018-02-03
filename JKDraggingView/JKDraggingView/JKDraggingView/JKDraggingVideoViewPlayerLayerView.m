//
//  JKDraggingVideoViewPlayerLayerView.m
//  JKDraggingView
//
//  Created by albert on 2018/2/3.
//  Copyright © 2018年 albert. All rights reserved.
//

#import "JKDraggingVideoViewPlayerLayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation JKDraggingVideoViewPlayerLayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+ (Class)layerClass{
    return [AVPlayerLayer class];
}
@end
