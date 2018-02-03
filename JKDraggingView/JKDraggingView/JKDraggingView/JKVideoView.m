//
//  JKVideoView.m
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "JKVideoView.h"
#import "UIView+JKExtension.h"
#import "NSTimer+JKExtension.h"
#import "JKDraggingVideoViewPlayerLayerView.h"

@interface JKVideoView () <CALayerDelegate>

/** 视频网址 */
@property (nonatomic, copy) NSString *videoUrl;

/** 播放器 */
@property (nonatomic, strong) AVPlayer *player;

/** 播放器的Layer */
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

/** AVPlayerItem */
@property (nonatomic, strong) AVPlayerItem *playerItem;

/** 放置播放器的Layer的view */
@property (nonatomic, weak) JKDraggingVideoViewPlayerLayerView *playerLayerView;

/** slogan */
@property (nonatomic, weak) UIImageView *sloganView;

/** 中间的IndicatorView */
@property (nonatomic, weak) UIActivityIndicatorView *middleIndicatorView;

/** 播放暂停按钮上的旋转控件 */
@property (nonatomic, weak) UIActivityIndicatorView *playIndicatorView;

/** 缓存的进度 */
@property (nonatomic, weak) UIProgressView *cacheProgressView;

/** 定时器 */
@property (nonatomic, strong) NSTimer *progressTimer;

/** 自动隐藏工具条的数值 */
@property (nonatomic, assign) int autoHideInterval;

/** 是否是用户手动暂停，不是的话，在程序变得活跃时自动播放。播放完毕也要置为YES */
@property (nonatomic, assign) BOOL isPausedByUser;

/** 是否已经监听了KVO */
@property (nonatomic, assign) BOOL isKVOAdded;

/** 暂停时的时间 */
@property (nonatomic, assign) Float64 currentTime;
@end

@implementation JKVideoView

+ (instancetype)viewWithItem:(JKDraggingVideoItem *)item frame:(CGRect)frame{
    JKVideoView *videoView = [[JKVideoView alloc] initWithFrame:frame];
    videoView.item = item;
    return videoView;
}

#pragma mark - 底部工具类的显示和隐藏
/**
 * 显示和隐藏底部工具栏及最底部进度条
 *
 * isShowBottomToolView : 是否显示底部工具栏
 * isShowBottomProgress : 是否显示最底部的进度条
 */
- (void)showBottomToolView:(BOOL)isShowBottomToolView isShowBottomProgress:(BOOL)isShowBottomProgress{
    
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomToolView.alpha = isShowBottomToolView ? 1 : 0;
        self.bottomProgressView.alpha = isShowBottomProgress ? 1 : 0;
        self.zoomButton.alpha = self.bottomToolView.alpha;
        self.outsideCloseButton.alpha = self.zoomButton.alpha;
        
    } completion:^(BOOL finished) {
        self.autoHideInterval = self.bottomToolView.alpha == 0 ? -2 : self.item.autoHideInterval;
    }];
}

/** 显示\隐藏底部工具类 自动切换 */
- (void)showOrHideBottomToolView{
    [self showBottomToolView:(self.bottomToolView.alpha <= 0) isShowBottomProgress:(self.bottomToolView.alpha >= 1)];
}

#pragma mark - 重播
- (void)replay{
    // 设置当前播放时间
    [self.player seekToTime:CMTimeMakeWithSeconds(0, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.player play];
    self.progressSlider.value = 0;
    self.bottomProgressView.progress = 0;
    [self addProgressTimer];
    
    !self.userDidReplayBlock ? : self.userDidReplayBlock();
}

#pragma mark - 播放完毕
- (void)playFinish{
    self.isPausedByUser = YES;
    [self removeProgressTimer];
    self.playOrPauseButton.selected = NO;
    [self.player pause];
    //    [self showBottomToolView:YES isShowBottomProgress:NO];
    
    !self.playFinishedBlock ? : self.playFinishedBlock();
}

#pragma mark - 播放\暂停
- (void)playOrPause:(UIButton *)button {
    if (self.middleIndicatorView.isAnimating) {
        button.selected = NO;
        return;
    }
    
    button.selected = !button.selected;
    if (button.selected) {
        
        if (self.progressSlider.value >= 1.0) {
            [self replay];
            return;
        }
        
        [self.player play];
        
        [self addProgressTimer];
        
    } else {
        [self pauseIsByUser:YES];
    }
}

- (void)pauseIsByUser:(BOOL)isByUser{
    self.playOrPauseButton.selected = NO;
    [self.middleIndicatorView stopAnimating];
    
    self.currentTime = CMTimeGetSeconds(self.player.currentTime);
    [self.player pause];
    
    [self removeProgressTimer];
    
    self.isPausedByUser = isByUser;
}

#pragma mark - 设置播放的视频
- (void)setItem:(JKDraggingVideoItem *)item{
    
    if ([_videoUrl isEqualToString:item.videoUrl]) {
        [self switchOrientation:self.changeToLandscapeButton];
        return;
    }
    _item = item;
    
    [self resetPlayView];
    
    _videoUrl = [_item.videoUrl copy];
    [self.middleIndicatorView startAnimating];
    [self.playIndicatorView startAnimating];
    self.playOrPauseButton.hidden = YES;
    
    self.autoHideInterval = _item.autoHideInterval + 1;
    self.bottomProgressView.progressTintColor = _item.bottomProgressColor;
    
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = (AVPlayerLayer *)self.playerLayerView.layer;
    [self.playerLayer setPlayer:self.player];
//    [self.playerLayerView.layer addSublayer:self.playerLayer];
    
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:_videoUrl]];
    
    [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    self.playOrPauseButton.selected = YES;
    
    // 监听PlayerItem这个类
    [self addAllObserverKVO];
}

#pragma mark - 监听playerItem的某些属性
// 监听获得消息
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) { // 监听状态
        if (playerItem.status == AVPlayerStatusReadyToPlay) {
            // status 点进去看 有三种状态
            
            CGFloat duration = playerItem.duration.value / playerItem.duration.timescale; // 视频总时间
            NSLog(@"准备好播放了，总时间：%.2f", duration);// 还可以获得播放的进度，这里可以给播放进度条赋值了
            
            [self.middleIndicatorView stopAnimating];
            self.sloganView.hidden = YES;
            [self.playIndicatorView stopAnimating];
            self.playOrPauseButton.hidden = NO;
            
            if (self.playOrPauseButton.selected == YES) {
                [self.player play];
            }
            
            [self updateProgressInfo];
            [self addProgressTimer];
            
        } else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown) {
            [self.player pause];
            [self.middleIndicatorView startAnimating];
            [self.playIndicatorView startAnimating];
            self.playOrPauseButton.hidden = YES;
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        
        NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        CMTime duration = playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        
        NSLog(@"下载进度：%.2f", timeInterval / totalDuration);
        self.cacheProgressView.progress = timeInterval / totalDuration;
        if (self.cacheProgressView.progress >= 1.0) {
            [self.progressSlider setMaximumTrackImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_slider_MaximumTrackImage@2x.png"]] forState:UIControlStateNormal];
            self.cacheProgressView.hidden = YES;
        }
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        if (playerItem.isPlaybackBufferEmpty) {
            
            NSLog(@"缓冲不足暂停了");
            [self.player pause];
            
            self.autoHideInterval = -2;
            [self removeProgressTimer];
            [self showBottomToolView:YES isShowBottomProgress:NO];
            
            [self.middleIndicatorView startAnimating];
            [self.playIndicatorView startAnimating];
            self.playOrPauseButton.hidden = YES;
        }
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        if (playerItem.isPlaybackLikelyToKeepUp) {
            NSLog(@"缓冲达到可播放程度了");
            
            //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
            [self.middleIndicatorView stopAnimating];
            [self.playIndicatorView stopAnimating];
            self.playOrPauseButton.hidden = NO;
            
            if (self.playOrPauseButton.selected == NO) {
                return;
            }
            
            [self.player play];
            self.autoHideInterval = self.item.autoHideInterval;
            [self addProgressTimer];
        }
    }
}

#pragma mark - 重置
- (void)suspendPlayVideo{
    [self.middleIndicatorView stopAnimating];
    
    self.playOrPauseButton.selected = NO;
    self.bottomToolView.alpha = 1;
    self.bottomProgressView.alpha = 0;
    
    [self.player pause];
    
    [self removeProgressTimer];
}

- (void)resetPlayView{
    
    [self removeAllObserverKVO];
    
    [self suspendPlayVideo];
    
    [self.playerLayer removeFromSuperlayer];
    
    self.playerLayer = nil;
    
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    
    // 把player置为nil
    self.player = nil;
    
    self.playerItem = nil;
}

#pragma mark - 切换横屏
- (void)switchOrientation:(UIButton *)button{
    button.selected = !button.selected;
    // TODO:切换横屏--------------------
    
    [self interfaceOrientation:button.selected ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait];
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation{
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

#pragma mark - 拖动进度条
- (void)startSlider{ // 开始拖动
    [self removeProgressTimer];
}

- (void)sliderValueChange:(UISlider *)slider{ // 拖动中
    
    [self removeProgressTimer];
    
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    self.videoTimeLabel.text = [self stringWithCurrentTime:currentTime duration:duration];
    self.bottomProgressView.progress = self.progressSlider.value;
}

- (void)endSlider:(UISlider *)slider{ // 拖动结束
    
    if (slider.value >= (CMTimeGetSeconds(self.player.currentItem.duration) - 0.3) / CMTimeGetSeconds(self.player.currentItem.duration)) {
        slider.value = (CMTimeGetSeconds(self.player.currentItem.duration) - 0.3) / CMTimeGetSeconds(self.player.currentItem.duration);
    }
    
    self.currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    
    // 设置当前播放时间
    [self.player seekToTime:CMTimeMakeWithSeconds(self.currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    if (!self.playOrPauseButton.selected) {
        return;
    }
    
    !self.userDidReplayBlock ? : self.userDidReplayBlock();
    
    [self.player play];
    [self addProgressTimer];
}

#pragma mark - 更新进度条及时间
- (void)updateProgressInfo{
    // 1.更新时间
    self.videoTimeLabel.text = [self timeString];
    
    // 2.设置进度条的value
    [self.progressSlider setValue:CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration) animated:YES];
    [self.bottomProgressView setProgress:self.progressSlider.value animated:YES];
    
    if (CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration) >= 1) {
        [self playFinish];
    }
    
    if (!self.progressTimer) {
        return;
    }
    
    self.autoHideInterval--;
    if (self.autoHideInterval < -1) return;
    
    if (self.autoHideInterval <= 0) {
        [self showBottomToolView:NO isShowBottomProgress:YES];
    }
}

- (NSString *)timeString{
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentTime);
    
    return [self stringWithCurrentTime:currentTime duration:duration];
}

- (NSString *)stringWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration{
    
    NSInteger dMin = duration / 60;
    NSInteger dSec = (NSInteger)duration % 60;
    
    NSInteger cMin = currentTime / 60;
    NSInteger cSec = (NSInteger)currentTime % 60;
    
    dMin = dMin<0?0:dMin;
    dSec = dSec<0?0:dSec;
    cMin = cMin<0?0:cMin;
    cSec = cSec<0?0:cSec;
    
    NSString *durationString = [NSString stringWithFormat:@"%02ld:%02ld", (long)dMin, (long)dSec];
    NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", (long)cMin, (long)cSec];
    
    return [NSString stringWithFormat:@"%@/%@", currentString, durationString];
}

#pragma mark - 定时器
- (void)addProgressTimer{
    if (self.progressTimer) {
        return;
    }
    
    self.autoHideInterval = self.item.autoHideInterval;
    
    __weak typeof(self) weakSelf = self;
    self.progressTimer = [NSTimer jk_scheduledTimerWithTimeInterval:1.0 repeats:YES isFire:NO timerBlock:^{
        [weakSelf updateProgressInfo];
    }];
}

- (void)removeProgressTimer{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialization];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
}
/*
- (void)layoutSubviews{
    [super layoutSubviews];
//        self.playerLayer.frame = self.layer.bounds;
    //    return;
    //    self.playerLayerView.frame = self.bounds;
    
    //    [CATransaction begin];
    //    // 显式事务默认开启动画效果,kCFBooleanTrue关闭
    //    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    //    // 动画执行时间
    //    [CATransaction setValue:[NSNumber numberWithFloat:0.001f] forKey:kCATransactionAnimationDuration];
    //
    //    //[CATransaction setAnimationDuration:[NSNumber numberWithFloat:5.0f]];
    //    self.playerLayer.bounds = CGRectMake(0, 0, self.playerLayerView.width, self.playerLayerView.height);
    //    self.playerLayer.position = CGPointMake(self.width * 0.5, self.height * 0.5);
    //    [CATransaction commit];
    
    //    if (self.isAllowLayerAnimation) {
    //
    //        self.playerLayer.bounds = CGRectMake(0, 0, self.playerLayerView.width, self.playerLayerView.height);
    //        self.playerLayer.position = CGPointMake(self.playerLayerView.width * 0.5, self.playerLayerView.height * 0.5);
    //        return;
    //    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
//    self.playerLayer.bounds = CGRectMake(0, 0, self.playerLayerView.width, self.playerLayerView.height);
//    self.playerLayer.position = CGPointMake(self.playerLayerView.width * 0.5, self.playerLayerView.height * 0.5);
    self.playerLayer.frame = self.layer.bounds;
    [CATransaction commit];
} */

//- (void)layoutSublayersOfLayer:(CALayer *)layer{
//    [super layoutSublayersOfLayer:layer];
//}

- (void)initialization{
    self.backgroundColor = [UIColor blackColor];
    
    // 静音也可以有声音
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self setupViews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 监听程序状态
- (void)applicationWillResignActiveNotification{
    
    [self removeAllObserverKVO];
    
    if (!self.playOrPauseButton.selected) return;
    
    [self pauseIsByUser:NO];
}

- (void)applicationDidBecomeActiveNotification{
    
    [self addAllObserverKVO];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(self.currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    if (self.isPausedByUser) {
        return;
    }
    
    self.playOrPauseButton.selected = YES;
    
    [self.player play];
    
    [self addProgressTimer];
}

- (void)setupViews{
    
    // slogan
    UIImageView *sloganView = [[UIImageView alloc] init];
    sloganView.backgroundColor = [UIColor darkGrayColor];
    [self addSubview:sloganView];
    self.sloganView = sloganView;
    
    // 约束
    sloganView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *sloganViewCenterX = [NSLayoutConstraint constraintWithItem:sloganView attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeCenterX) multiplier:1 constant:0];
    NSLayoutConstraint *sloganViewCenterY = [NSLayoutConstraint constraintWithItem:sloganView attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
    NSLayoutConstraint *sloganViewW = [NSLayoutConstraint constraintWithItem:sloganView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:80];
    NSLayoutConstraint *sloganViewH = [NSLayoutConstraint constraintWithItem:sloganView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:80];
    [self addConstraints:@[sloganViewCenterX, sloganViewCenterY, sloganViewW, sloganViewH]];
    
    JKDraggingVideoViewPlayerLayerView *playerLayerView = [[JKDraggingVideoViewPlayerLayerView alloc] init];
    playerLayerView.clipsToBounds = YES;
    [self addSubview:playerLayerView];
    self.playerLayerView = playerLayerView;
    
    // 约束
    playerLayerView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *playerLayerViewTop = [NSLayoutConstraint constraintWithItem:playerLayerView attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTop) multiplier:1 constant:0];
    NSLayoutConstraint *playerLayerViewBottom = [NSLayoutConstraint constraintWithItem:playerLayerView attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
    NSLayoutConstraint *playerLayerViewLeft = [NSLayoutConstraint constraintWithItem:playerLayerView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    NSLayoutConstraint *playerLayerViewRight = [NSLayoutConstraint constraintWithItem:playerLayerView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    [self addConstraints:@[playerLayerViewTop, playerLayerViewBottom, playerLayerViewLeft, playerLayerViewRight]];
    
    // 底部工具条及最底部进度条
    [self setupBottomToolView];
    
    // 中间的旋转控件
    UIActivityIndicatorView *middleIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhiteLarge)];
    [self addSubview:middleIndicatorView];
    self.middleIndicatorView = middleIndicatorView;
    
    // 约束
    middleIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *middleIndicatorViewCenterX = [NSLayoutConstraint constraintWithItem:middleIndicatorView attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeCenterX) multiplier:1 constant:0];
    NSLayoutConstraint *middleIndicatorViewCenterY = [NSLayoutConstraint constraintWithItem:middleIndicatorView attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
    NSLayoutConstraint *middleIndicatorViewW = [NSLayoutConstraint constraintWithItem:middleIndicatorView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:37];
    NSLayoutConstraint *middleIndicatorViewH = [NSLayoutConstraint constraintWithItem:middleIndicatorView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:37];
    [self addConstraints:@[middleIndicatorViewCenterX, middleIndicatorViewCenterY, middleIndicatorViewW, middleIndicatorViewH]];
}

- (void)setupBottomToolView{
    
    // 底部工具条
    UIView *bottomToolView = [[UIView alloc] init];
    bottomToolView.backgroundColor = [UIColor clearColor];
    [self addSubview:bottomToolView];
    _bottomToolView = bottomToolView;
    
    // 约束
    bottomToolView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *bottomToolViewLeft = [NSLayoutConstraint constraintWithItem:bottomToolView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    NSLayoutConstraint *bottomToolViewRight = [NSLayoutConstraint constraintWithItem:bottomToolView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    NSLayoutConstraint *bottomToolViewBottom = [NSLayoutConstraint constraintWithItem:bottomToolView attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
    NSLayoutConstraint *bottomToolViewH = [NSLayoutConstraint constraintWithItem:bottomToolView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    [self addConstraints:@[bottomToolViewLeft, bottomToolViewRight, bottomToolViewBottom, bottomToolViewH]];
    
    // 最底部进度条
    UIProgressView *bottomProgressView = [[UIProgressView alloc] init];
    bottomProgressView.clipsToBounds = YES;
    bottomProgressView.trackTintColor = [UIColor lightGrayColor];
    bottomProgressView.progressTintColor = [UIColor redColor];
    [self addSubview:bottomProgressView];
    _bottomProgressView = bottomProgressView;
    
    // 约束
    bottomProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *bottomProgressViewLeft = [NSLayoutConstraint constraintWithItem:bottomProgressView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    NSLayoutConstraint *bottomProgressViewRight = [NSLayoutConstraint constraintWithItem:bottomProgressView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    NSLayoutConstraint *bottomProgressViewBottom = [NSLayoutConstraint constraintWithItem:bottomProgressView attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
    NSLayoutConstraint *bottomProgressViewH = [NSLayoutConstraint constraintWithItem:bottomProgressView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:0.5];
    [self addConstraints:@[bottomProgressViewLeft, bottomProgressViewRight, bottomProgressViewBottom, bottomProgressViewH]];
    
    // 开始暂停按钮
    JKDraggingVideoViewNoHighlightedButton *playOrPauseButton = [JKDraggingVideoViewNoHighlightedButton buttonWithType:(UIButtonTypeCustom)];
    [self.bottomToolView addSubview:playOrPauseButton];
    _playOrPauseButton = playOrPauseButton;
    [playOrPauseButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_play@3x.png"]] forState:(UIControlStateNormal)];
    [playOrPauseButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_pause@3x.png"]] forState:(UIControlStateSelected)];
    // 点击事件
    [playOrPauseButton addTarget:self action:@selector(playOrPause:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 约束
    playOrPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *playOrPauseButtonLeft = [NSLayoutConstraint constraintWithItem:playOrPauseButton attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    NSLayoutConstraint *playOrPauseButtonTop = [NSLayoutConstraint constraintWithItem:playOrPauseButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeTop) multiplier:1 constant:0];
    NSLayoutConstraint *playOrPauseButtonBottom = [NSLayoutConstraint constraintWithItem:playOrPauseButton attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
    NSLayoutConstraint *playOrPauseButtonW = [NSLayoutConstraint constraintWithItem:playOrPauseButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    [self.bottomToolView addConstraints:@[playOrPauseButtonLeft, playOrPauseButtonTop, playOrPauseButtonBottom, playOrPauseButtonW]];
    
    // 播放暂停按钮上的旋转控件
    UIActivityIndicatorView *playIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhite)];
    [self.bottomToolView addSubview:playIndicatorView];
    self.playIndicatorView = playIndicatorView;
    
    // 约束
    playIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *playIndicatorViewCenterX = [NSLayoutConstraint constraintWithItem:playIndicatorView attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:playOrPauseButton attribute:(NSLayoutAttributeCenterX) multiplier:1 constant:0];
    NSLayoutConstraint *playIndicatorViewCenterY = [NSLayoutConstraint constraintWithItem:playIndicatorView attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:playOrPauseButton attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
    [self.bottomToolView addConstraints:@[playIndicatorViewCenterX, playIndicatorViewCenterY]];
    
    // 切换横屏按钮
    UIButton *changeToLandscapeButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [changeToLandscapeButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_to_landscape@2x.png"]] forState:(UIControlStateNormal)];
    [changeToLandscapeButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_to_portrait@2x.png"]] forState:(UIControlStateSelected)];
    [self.bottomToolView addSubview:changeToLandscapeButton];
    _changeToLandscapeButton = changeToLandscapeButton;
    
    [changeToLandscapeButton addTarget:self action:@selector(switchOrientation:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 约束
    changeToLandscapeButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *changeToLandscapeButtonTop = [NSLayoutConstraint constraintWithItem:changeToLandscapeButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeTop) multiplier:1 constant:0];
    NSLayoutConstraint *changeToLandscapeButtonRight = [NSLayoutConstraint constraintWithItem:changeToLandscapeButton attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    NSLayoutConstraint *changeToLandscapeButtonBottom = [NSLayoutConstraint constraintWithItem:changeToLandscapeButton attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
    NSLayoutConstraint *changeToLandscapeButtonW = [NSLayoutConstraint constraintWithItem:changeToLandscapeButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    [self.bottomToolView addConstraints:@[changeToLandscapeButtonTop, changeToLandscapeButtonRight, changeToLandscapeButtonBottom, changeToLandscapeButtonW]];
    
    // 视频时间
    UILabel *videoTimeLabel = [[UILabel alloc] init];
    videoTimeLabel.textAlignment = NSTextAlignmentRight;
    videoTimeLabel.font = [UIFont systemFontOfSize:12];
    videoTimeLabel.textColor = [UIColor whiteColor];
    videoTimeLabel.text = @"--:--/--:--";
    [self.bottomToolView addSubview:videoTimeLabel];
    _videoTimeLabel = videoTimeLabel;
    
    // 约束
    videoTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *videoTimeLabelRight = [NSLayoutConstraint constraintWithItem:videoTimeLabel attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:changeToLandscapeButton attribute:(NSLayoutAttributeLeft) multiplier:1 constant:-10];
    NSLayoutConstraint *videoTimeLabelCenterY = [NSLayoutConstraint constraintWithItem:videoTimeLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
    NSLayoutConstraint *videoTimeLabelWidth = [NSLayoutConstraint constraintWithItem:videoTimeLabel attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:90];
    [self.bottomToolView addConstraints:@[videoTimeLabelRight, videoTimeLabelCenterY, videoTimeLabelWidth]];
    
    // 进度条
    UISlider *slider = [[UISlider alloc] init];
    slider.clipsToBounds = YES;
    [self.bottomToolView addSubview:slider];
    _progressSlider = slider;
    
    [slider addTarget:self action:@selector(startSlider) forControlEvents:(UIControlEventTouchDown)];
    [slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:(UIControlEventValueChanged)];
    [slider addTarget:self action:@selector(endSlider:) forControlEvents:(UIControlEventTouchUpInside)];
    [slider addTarget:self action:@selector(endSlider:) forControlEvents:(UIControlEventTouchUpOutside)];
    
    // 约束
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *sliderLeft = [NSLayoutConstraint constraintWithItem:slider attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:playOrPauseButton attribute:(NSLayoutAttributeRight) multiplier:1 constant:10];
    NSLayoutConstraint *sliderCenterY = [NSLayoutConstraint constraintWithItem:slider attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
    NSLayoutConstraint *sliderRight = [NSLayoutConstraint constraintWithItem:slider attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:videoTimeLabel attribute:(NSLayoutAttributeLeft) multiplier:1 constant:-10];
    [self.bottomToolView addConstraints:@[sliderLeft, sliderCenterY, sliderRight]];
    
    self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
    [self.progressSlider setThumbImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_slider_thumbImage@2x.png"]] forState:UIControlStateNormal];
    [self.progressSlider setMinimumTrackImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_slider_MinimumTrackImage@2x.png"]] forState:UIControlStateNormal];
    
    // 缓存的进度条
    UIProgressView *cacheProgressView = [[UIProgressView alloc] init];
    cacheProgressView.trackTintColor = [UIColor whiteColor];
    cacheProgressView.progressTintColor = [UIColor lightGrayColor];
    [self.bottomToolView insertSubview:cacheProgressView belowSubview:slider];
    self.cacheProgressView = cacheProgressView;
    
    // 约束
    cacheProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *cacheProgressViewCenterY = [NSLayoutConstraint constraintWithItem:cacheProgressView attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:slider attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:1];
    NSLayoutConstraint *cacheProgressViewLeft = [NSLayoutConstraint constraintWithItem:cacheProgressView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:slider attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    NSLayoutConstraint *cacheProgressViewRight = [NSLayoutConstraint constraintWithItem:cacheProgressView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:slider attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    NSLayoutConstraint *cacheProgressViewHeight = [NSLayoutConstraint constraintWithItem:cacheProgressView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:0.5];
    
    [self.bottomToolView addConstraints:@[cacheProgressViewCenterY, cacheProgressViewLeft, cacheProgressViewRight, cacheProgressViewHeight]];
    
    // 内部的关闭按钮
    UIButton *insideCloseButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [insideCloseButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_close@3x.png"]] forState:(UIControlStateNormal)];
    [self addSubview:insideCloseButton];
    _insideCloseButton = insideCloseButton;
    
    [insideCloseButton addTarget:self action:@selector(closeVideo) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 约束
    insideCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *insideCloseButtonTop = [NSLayoutConstraint constraintWithItem:insideCloseButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTop) multiplier:1 constant:2];
    
    NSLayoutConstraint *insideCloseButtonRight = [NSLayoutConstraint constraintWithItem:insideCloseButton attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:-2];
    
    NSLayoutConstraint *insideCloseButtonWidth = [NSLayoutConstraint constraintWithItem:insideCloseButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:18];
    
    NSLayoutConstraint *insideCloseButtonHeight = [NSLayoutConstraint constraintWithItem:insideCloseButton attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:18];
    
    [self addConstraints:@[insideCloseButtonTop, insideCloseButtonRight, insideCloseButtonWidth, insideCloseButtonHeight]];
}

#pragma mark - 关闭视频
- (void)closeVideo{
    [self resetPlayView];
    
    [self showBottomToolView:NO isShowBottomProgress:NO];
    [_bottomToolView removeFromSuperview];
    [_bottomProgressView removeFromSuperview];
    [_playerLayerView removeFromSuperview];
    [_sloganView removeFromSuperview];
    _bottomToolView = nil;
    _bottomProgressView = nil;
    _playerLayerView = nil;
    _sloganView = nil;
    
    !self.closeBlock ? : self.closeBlock();
    
    [self removeFromSuperview];
}

#pragma mark - KVO
- (void)addAllObserverKVO{
    if (!self.playerItem) return;
    
    if (self.isKVOAdded) return;
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    self.isKVOAdded = YES;
}

- (void)removeAllObserverKVO{
    
    if (!self.isKVOAdded) return;
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    self.isKVOAdded = NO;
}

- (void)dealloc {
    [self removeAllObserverKVO];
    [self resetPlayView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end




@implementation JKDraggingVideoViewNoHighlightedButton
- (void)setHighlighted:(BOOL)highlighted{}
@end
