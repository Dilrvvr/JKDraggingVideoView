//
//  JKDraggingVideoItem.m
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "JKDraggingVideoItem.h"
#import "UIView+JKExtension.h"
#import <AVFoundation/AVFoundation.h>

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
        self.screenInsets = UIEdgeInsetsMake(JKDraggingVideoIsIphoneX ? 54 : 30, 10, JKDraggingVideoIsIphoneX ? 44 : 10, 10);
        self.videoOriginalSize = CGSizeMake(JKDraggingVideoScreenW, JKDraggingVideoScreenW / 16 * 9);
    }
    return self;
}

- (void)setVideoOriginalSize:(CGSize)videoOriginalSize{
    _videoOriginalSize = videoOriginalSize;
    
    [self calculateVideoPortraitSize];
    [self calculateVideoLandscapeSize];
    
    if (([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)) {
        
//        [UIView changeInterfaceOrientation:(UIInterfaceOrientationPortrait)];
        
        tmpSize = _videoPortraitSize;
        _videoPortraitSize = _videoLandscapeSize;
        _videoLandscapeSize = tmpSize;
    }
}

// 计算竖屏视频尺寸
- (void)calculateVideoPortraitSize{
    
    if (_videoOriginalSize.width <= JKDraggingVideoScreenW && _videoOriginalSize.height <= (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH)) {
        _videoPortraitSize = _videoOriginalSize;
        return;
    }
    
    if ((_videoOriginalSize.width > JKDraggingVideoScreenW) || (_videoOriginalSize.height > (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH))) {
        
        CGFloat W = JKDraggingVideoScreenW;
        CGFloat H = JKDraggingVideoScreenW * _videoOriginalSize.height / _videoOriginalSize.width;
        if (H > (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH)) {
            H = (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH);
            W = H * _videoOriginalSize.width / _videoOriginalSize.height;
        }
        _videoPortraitSize = CGSizeMake(W, H);
        return;
    }
}

// 计算横屏视频尺寸
- (void)calculateVideoLandscapeSize{
    
    if (_videoOriginalSize.width <= (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH) && _videoOriginalSize.height <= JKDraggingVideoScreenW) {
        _videoLandscapeSize = _videoOriginalSize;
        return;
    }
    
    if ((_videoOriginalSize.width > (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH)) || (_videoOriginalSize.height > JKDraggingVideoScreenW)) {
        CGFloat W = (JKDraggingVideoIsIphoneX ? JKDraggingVideoScreenH - 88 : JKDraggingVideoScreenH);
        CGFloat H = W * _videoOriginalSize.height / _videoOriginalSize.width;
        if (H > JKDraggingVideoScreenW) {
            H = JKDraggingVideoScreenW;
            W = JKDraggingVideoScreenW * _videoOriginalSize.width / _videoOriginalSize.height;
        }
        _videoLandscapeSize = CGSizeMake(W, H);
        return;
    }
}

//videoPortraitSize
//videoLandscapeSize


/** 获取视频的尺寸 */
+ (void)getVideoSizeWithURL:(NSURL *)URL complete:(void(^)(CGSize videoSize))complete{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:URL options:nil];
    
    // 获取
    // loadValuesAsynchronouslyForKeys是官方提供异步加载track的方法，防止线程阻塞
    // 加载track是耗时操作
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        
        // 一般视频都有至少两个track(轨道)，根据track.mediaType判断track类型
        // AVMediaTypeVideo表示视频轨道，AVMediaTypeAudio代表音频轨道，其他类型可以查看文档。
        // 根据track的naturalSize属性即可获得视频尺寸
        NSArray *array = asset.tracks;
        CGSize videoSize = CGSizeZero;
        
        for (AVAssetTrack *track in array) {
            
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                
                // 注意修正naturalSize的宽高
                videoSize = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);//CGSizeMake(track.naturalSize.height, track.naturalSize.width);
                
                break;
            }
        }
        
        if (asset.playable) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                !complete ? : complete(videoSize);
            });
        }
    }];
}
@end
