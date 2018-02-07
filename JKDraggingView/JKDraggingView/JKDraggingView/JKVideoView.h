//
//  JKVideoView.h
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "JKDraggingVideoItem.h"

@interface JKVideoView : UIView
/** 配置的模型 */
@property (nonatomic, strong) JKDraggingVideoItem *item;

/** 关闭按钮 由外界赋值，内部并不创建，内部只控制其隐藏和显示 */
@property (nonatomic, weak) UIButton *outsideCloseButton;

/** 缩放按钮 由外界赋值，内部并不创建，内部只控制其隐藏和显示 */
@property (nonatomic, weak) UIButton *zoomButton;

/** 内部关闭按钮 */
@property (nonatomic, weak,readonly) UIButton *insideCloseButton;

/** 底部工具栏容器view */
@property (nonatomic, weak, readonly) UIView *bottomToolView;

/** 播放时间进度条 */
@property (nonatomic, weak, readonly) UISlider *progressSlider;

/** 开始暂停按钮 */
@property (nonatomic, weak, readonly) UIButton *playOrPauseButton;

/** 视频时间label */
@property (nonatomic, weak, readonly) UILabel *videoTimeLabel;

/** 切换横屏按钮 */
@property (nonatomic, weak, readonly) UIButton *changeToLandscapeButton;

/** 底部进度条 */
@property (nonatomic, weak, readonly) UIProgressView *bottomProgressView;

/** 监听播放完毕的block */
@property (nonatomic, copy) void (^playFinishedBlock)();

/** 监听重播或拖动进度条重播的block */
@property (nonatomic, copy) void (^userDidReplayBlock)();

/** 监听关闭的block */
@property (nonatomic, copy) void (^closeBlock)();

+ (instancetype)viewWithItem:(JKDraggingVideoItem *)item frame:(CGRect)frame;

/**
 * 显示和隐藏底部工具栏及最底部进度条
 *
 * isShowBottomToolView : 是否显示底部工具栏
 * isShowBottomProgress : 是否显示最底部的进度条
 */
- (void)showBottomToolView:(BOOL)isShowBottomToolView isShowBottomProgress:(BOOL)isShowBottomProgress;

/** 显示\隐藏底部工具类 自动切换 */
- (void)showOrHideBottomToolView;

#pragma mark - 播放\暂停
- (void)playOrPause:(UIButton *)button;

#pragma mark - 切换横屏
- (void)switchOrientation:(UIButton *)button;

#pragma mark - 拖动进度条
- (void)startSlider;

- (void)sliderValueChange:(UISlider *)slider;

- (void)endSlider:(UISlider *)slider;

- (void)pauseIsByUser:(BOOL)isByUser;

- (void)suspendPlayVideo;

- (void)resetPlayView;
@end



@interface JKDraggingVideoViewPlayerLayerView : UIView

@end
