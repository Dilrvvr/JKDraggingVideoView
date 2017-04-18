//
//  JKDraggingVideoItem.m
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "JKDraggingVideoItem.h"
#import "UIView+JKExtension.h"

@interface JKDraggingVideoItem () {
    /** 临时的尺寸,修正横竖屏尺寸 */
    CGSize tmpSize;
}
@end

@implementation JKDraggingVideoItem
- (instancetype)init{
    if (self = [super init]) {
        self.autoHideInterval = 5;
        self.bottomProgressColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
        self.screenInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

- (void)setVideoOriginalSize:(CGSize)videoOriginalSize{
    _videoOriginalSize = videoOriginalSize;
    
    [self calculateVideoPortraitSize];
    [self calculateVideoLandscapeSize];
    
    if (([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)) {
        
        [UIView changeInterfaceOrientation:(UIInterfaceOrientationPortrait)];
        
        tmpSize = _videoPortraitSize;
        _videoPortraitSize = _videoLandscapeSize;
        _videoLandscapeSize = tmpSize;
    }
}

// 计算竖屏视频尺寸
- (void)calculateVideoPortraitSize{
    if (_videoOriginalSize.width <= JKScreenW && _videoOriginalSize.height <= JKScreenH) {
        _videoPortraitSize = _videoOriginalSize;
        return;
    }
    
    if ((_videoOriginalSize.width > JKScreenW) || (_videoOriginalSize.height > JKScreenH)) {
        CGFloat W = JKScreenW;
        CGFloat H = JKScreenW * _videoOriginalSize.height / _videoOriginalSize.width;
        if (H > JKScreenH) {
            H = JKScreenH;
            W = JKScreenH * _videoOriginalSize.width / _videoOriginalSize.height;
        }
        _videoPortraitSize = CGSizeMake(W, H);
        return;
    }
}

// 计算横屏视频尺寸
- (void)calculateVideoLandscapeSize{
    if (_videoOriginalSize.width <= JKScreenH && _videoOriginalSize.height <= JKScreenW) {
        _videoLandscapeSize = _videoOriginalSize;
        return;
    }
    
    if ((_videoOriginalSize.width > JKScreenH) || (_videoOriginalSize.height > JKScreenW)) {
        CGFloat W = JKScreenH;
        CGFloat H = JKScreenH * _videoOriginalSize.height / _videoOriginalSize.width;
        if (H > JKScreenW) {
            H = JKScreenW;
            W = JKScreenW * _videoOriginalSize.width / _videoOriginalSize.height;
        }
        _videoLandscapeSize = CGSizeMake(W, H);
        return;
    }
}

//videoPortraitSize
//videoLandscapeSize
@end
