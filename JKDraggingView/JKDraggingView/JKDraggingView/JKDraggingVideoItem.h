//
//  JKDraggingVideoItem.h
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

@import UIKit;
#import "JKDraggingVideoViewMacro.h"

@class JKVideoView;

@interface JKDraggingVideoItem : NSObject
/** 缩小后 悬浮屏幕四周的间距 默认全是10 */
@property (nonatomic, assign) UIEdgeInsets screenInsets;

/** 视频url */
@property (nonatomic, copy) NSString *videoUrl;

/** 视频尺寸 */
@property (nonatomic, assign) CGSize videoOriginalSize;

/** 自动隐藏工具栏的时间 默认5s 设置为-2及更小。即代表不自动隐藏 */
@property (nonatomic, assign) int autoHideInterval;

/** 最底部没有工具栏时显示的进度条的颜色 默认红色 */
@property (nonatomic, strong) UIColor *bottomProgressColor;


/** 视频竖屏尺寸 */
@property (nonatomic, assign, readonly) CGSize videoPortraitSize;

/** 视频横屏尺寸 */
@property (nonatomic, assign, readonly) CGSize videoLandscapeSize;
@end
