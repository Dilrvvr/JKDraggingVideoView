//
//  JKDraggingVideoView.h
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKDraggingVideoItem.h"

@interface JKDraggingVideoView : UIView

/** 配置的模型 */
@property (nonatomic, strong, readonly) JKDraggingVideoItem *item;

/** 监听放大和缩小的block */
@property (nonatomic, copy) void (^changeToSmallWindowBlock)(BOOL isSmallWindow);

+ (instancetype)showWithItem:(JKDraggingVideoItem *)item;

+ (void)play;

+ (void)pause;

+ (void)close;
@end
