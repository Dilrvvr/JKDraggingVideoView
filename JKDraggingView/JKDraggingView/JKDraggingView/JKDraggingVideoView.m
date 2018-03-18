//
//  JKDraggingVideoView.m
//  JKDraggingView
//
//  Created by albert on 2017/3/19.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "JKDraggingVideoView.h"
#import "UIView+JKExtension.h"
#import "JKVideoView.h"

@interface JKDraggingVideoView () {
    CGPoint FinalCenter;
    CGPoint ScreenCenter;
    CGFloat finalWidth;
    CGFloat finalHeight;
    BOOL isFullScreen;
    BOOL isSmallWindow;
    BOOL isDragging;
    CGFloat distance;
}

/** 播放器view */
@property (nonatomic, weak) JKVideoView *videoView;

/** 关闭按钮 */
@property (nonatomic, weak) UIButton *closeButton;

/** 缩放按钮 */
@property (nonatomic, weak) UIButton *zoomButton;

/** 重播按钮 */
@property (nonatomic, weak) UIButton *replayButton;

/** 分享按钮 */
@property (nonatomic, weak) UIButton *shareButton;

/** 底部工具栏容器view */
@property (nonatomic, weak, readonly) UIView *bottomToolView;

/** 底部进度条 */
@property (nonatomic, weak, readonly) UIProgressView *bottomProgressView;

/** 播放时间进度条 */
@property (nonatomic, weak) UISlider *progressSlider;

/** 开始暂停按钮 */
@property (nonatomic, weak) UIButton *playOrPauseButton;

/** 视频时间label */
@property (nonatomic, weak) UILabel *videoTimeLabel;

/** 切换横屏按钮 */
@property (nonatomic, weak) UIButton *changeToLandscapeButton;

/** 是否播放完毕 */
@property (nonatomic, assign) BOOL isPlayFinished;

/** 单击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

/** 双击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@end

@implementation JKDraggingVideoView

static JKDraggingVideoView *vv;

+ (instancetype)showWithItem:(JKDraggingVideoItem *)item{
    
    if (!vv) {
        
        vv = [[JKDraggingVideoView alloc] initWithFrame:JKScreenBounds];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JKTurnOnAutoRotateNotification object:nil];
        
    }else{
        if (!vv.userInteractionEnabled) {
            return nil;
        }
        
        [vv changeToFullScreen];
        
        if ([item.videoUrl isEqualToString:vv.item.videoUrl]) {
            
            return vv;
        }
        
        [vv.bottomToolView removeFromSuperview];
        [vv.bottomProgressView removeFromSuperview];
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:vv];
    [UIApplication sharedApplication].statusBarHidden = YES;
    vv.item = item;
    
    return vv;
}

+ (void)play{
    
    vv.playOrPauseButton.selected = NO;
    [vv.videoView playOrPause:vv.playOrPauseButton];
}

+ (void)pause{
    
    vv.playOrPauseButton.selected = YES;
    [vv.videoView playOrPause:vv.playOrPauseButton];
}

+ (void)close{
    [vv removeVideoView];
}

#pragma mark - 设置播放器view
- (JKVideoView *)videoView{
    if (!_videoView) {
        JKVideoView *videoView = [[JKVideoView alloc] init];
        videoView.frame = CGRectMake(0, 0, _item.videoPortraitSize.width, _item.videoPortraitSize.height);
        videoView.center = self.center;
        [self insertSubview:videoView atIndex:0];
        videoView.insideCloseButton.hidden = YES;
        videoView.outsideCloseButton = self.closeButton;
        videoView.zoomButton = self.zoomButton;
        
        [self addSubview:videoView.bottomToolView];
        //        [self addSubview:videoView.bottomProgressView];
        
        __weak typeof(self) weakSelf = self;
        [videoView setPlayFinishedBlock:^{
            
            [weakSelf playFinish];
        }];
        
        [videoView setUserDidReplayBlock:^{
            weakSelf.isPlayFinished = NO;
        }];
        
        [videoView setCloseBlock:^{
            [weakSelf removeVideoView];
        }];
        
        _videoView = videoView;
    }
    return _videoView;
}

- (void)setItem:(JKDraggingVideoItem *)item{
    
    _item = item;
    
    [_videoView resetPlayView];
    [_videoView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_videoView removeFromSuperview];
    _videoView = nil;
    
    self.videoView.item = _item;
    
    [self setupBottomToolView];
    [self calculateFinalCenter];
}

#pragma mark - 播放完毕
- (void)playFinish{
    self.isPlayFinished = YES;
    
    if (isSmallWindow) {
        [self removeVideoView];
        return;
    }
    
    [self showReplayAndShare];
}

- (void)showReplayAndShare{
    
    if (isDragging) {
        return;
    }
    [self.videoView showBottomToolView:YES isShowBottomProgress:NO];
}

- (void)replay{
    
}

- (void)share{
    
}

#pragma mark - 计算最终缩小后的中心点
- (void)calculateFinalCenter{
    
    CGFloat maxW = JKScreenW * 0.45 - 20;
    CGFloat maxH = JKScreenH * 0.25 - 20;
    
    finalWidth = maxW;
    finalHeight = maxW * self.videoView.height / self.videoView.width;
    if (finalHeight > maxH) {
        finalHeight = maxH;
        finalWidth = maxH * self.videoView.width / self.videoView.height;
    }
    
    FinalCenter = CGPointMake(JKScreenW - finalWidth * 0.5 - self.item.screenInsets.right, JKScreenH - finalHeight * 0.5 - self.item.screenInsets.bottom);
}

#pragma mark - 播放\暂停
- (void)playOrPause:(UIButton *)button{
    [self.videoView playOrPause:button];
}

#pragma mark - 切换横屏
- (void)switchOrientation:(UIButton *)button{
    [self.videoView switchOrientation:button];
    
}

#pragma mark - 拖动进度条
- (void)startSlider{
    [self.videoView startSlider];
}

- (void)sliderValueChange:(UISlider *)slider{
    [self.videoView sliderValueChange:slider];
}

- (void)endSlider:(UISlider *)slider{
    [self.videoView endSlider:slider];
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

- (void)initialization{
    self.backgroundColor = [UIColor blackColor];
    
    [self addDoubleTap];
    
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    closeButton.adjustsImageWhenHighlighted = NO;
    [closeButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_close_full@3x.png"]] forState:(UIControlStateNormal)];
    [self addSubview:closeButton];
    self.closeButton = closeButton;
    
    [closeButton addTarget:self action:@selector(removeVideoView) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 约束
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *closeButtonTop = [NSLayoutConstraint constraintWithItem:closeButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTop) multiplier:1 constant:JKIsIphoneX ? 44 : 30];
    NSLayoutConstraint *closeButtonLeft = [NSLayoutConstraint constraintWithItem:closeButton attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeLeft) multiplier:1 constant:20];
    NSLayoutConstraint *closeButtonWidth = [NSLayoutConstraint constraintWithItem:closeButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    NSLayoutConstraint *closeButtonHeight = [NSLayoutConstraint constraintWithItem:closeButton attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    [self addConstraints:@[closeButtonTop, closeButtonLeft, closeButtonWidth, closeButtonHeight]];
    
    // 缩小为窗口按钮
    UIButton *zoomButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    zoomButton.adjustsImageWhenHighlighted = NO;
    [zoomButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKVideoViewResource.bundle/images/player_zoom@3x.png"]] forState:(UIControlStateNormal)];
    [self addSubview:zoomButton];
    self.zoomButton = zoomButton;
    
    [zoomButton addTarget:self action:@selector(changeToSmallWindow) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 约束
    zoomButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *zoomButtonTop = [NSLayoutConstraint constraintWithItem:zoomButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTop) multiplier:1 constant:JKIsIphoneX ? 44 : 30];
    NSLayoutConstraint *zoomButtonRight = [NSLayoutConstraint constraintWithItem:zoomButton attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:-20];
    NSLayoutConstraint *zoomButtonWidth = [NSLayoutConstraint constraintWithItem:zoomButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    NSLayoutConstraint *zoomButtonHeight = [NSLayoutConstraint constraintWithItem:zoomButton attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    [self addConstraints:@[zoomButtonTop, zoomButtonRight, zoomButtonWidth, zoomButtonHeight]];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    isFullScreen = (self.width >= JKScreenW && self.height >= JKScreenH);
    
    distance = 0;
    ScreenCenter = CGPointMake(JKScreenW * 0.5, JKScreenH * 0.5);
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    self.singleTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:self.singleTap];
    
    // 监听屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)addDoubleTap{
    
    if (!self.doubleTap) {
        
        self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    }
    
    self.doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:self.doubleTap];
    
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
}

- (void)statusBarOrientationChange:(NSNotification *)notification{
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (isSmallWindow) {
        return;
    }
    
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation ==UIInterfaceOrientationLandscapeLeft) // home键靠右左
    {
        NSLog(@"home键靠右左");
        
        [self changeScreenIsToLandscape:YES];
    }
    
    //    if (orientation ==UIInterfaceOrientationLandscapeLeft) // home键靠左
    //    {
    //        NSLog(@"home键靠左");
    //    }
    
    if (orientation == UIInterfaceOrientationPortrait)
    {
        NSLog(@"竖屏");
        [self changeScreenIsToLandscape:NO];
    }
    
    if (orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        NSLog(@"UpsideDown");
    }
}

- (void)changeScreenIsToLandscape:(BOOL)isToLandscape{
    self.changeToLandscapeButton.selected = isToLandscape;
    
    self.frame = JKScreenBounds;
    
    self.videoView.size = isToLandscape ? self.item.videoLandscapeSize : self.item.videoPortraitSize;
    self.videoView.center = CGPointMake(self.width * 0.5, self.height * 0.5);
}

// 设置底部工具条等视图
- (void)setupBottomToolView{
    // 底部工具条
    _bottomToolView = self.videoView.bottomToolView;
    // 最底部进度条
    _bottomProgressView = self.videoView.bottomProgressView;
    // 开始暂停按钮
    _playOrPauseButton = self.videoView.playOrPauseButton;
    // 切换横屏按钮
    _changeToLandscapeButton = self.videoView.changeToLandscapeButton;
    // 视频时间
    _videoTimeLabel = self.videoView.videoTimeLabel;
    // 进度条
    _progressSlider = self.videoView.progressSlider;
    
    // 约束
    _bottomToolView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *bottomToolViewLeft = [NSLayoutConstraint constraintWithItem:_bottomToolView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    NSLayoutConstraint *bottomToolViewRight = [NSLayoutConstraint constraintWithItem:_bottomToolView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    NSLayoutConstraint *bottomToolViewBottom = [NSLayoutConstraint constraintWithItem:_bottomToolView attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeBottom) multiplier:1 constant:JKIsIphoneX ? -34 : 0];
    NSLayoutConstraint *bottomToolViewH = [NSLayoutConstraint constraintWithItem:_bottomToolView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
    [self addConstraints:@[bottomToolViewLeft, bottomToolViewRight, bottomToolViewBottom, bottomToolViewH]];
    /*
     // 最底部进度条
     _bottomProgressView = self.videoView.bottomProgressView;
     
     // 约束
     _bottomProgressView.translatesAutoresizingMaskIntoConstraints = NO;
     NSLayoutConstraint *bottomProgressViewLeft = [NSLayoutConstraint constraintWithItem:_bottomProgressView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
     NSLayoutConstraint *bottomProgressViewRight = [NSLayoutConstraint constraintWithItem:_bottomProgressView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
     NSLayoutConstraint *bottomProgressViewBottom = [NSLayoutConstraint constraintWithItem:_bottomProgressView attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
     NSLayoutConstraint *bottomProgressViewH = [NSLayoutConstraint constraintWithItem:_bottomProgressView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:1];
     [self addConstraints:@[bottomProgressViewLeft, bottomProgressViewRight, bottomProgressViewBottom, bottomProgressViewH]];
     
     // 开始暂停按钮
     self.playOrPauseButton = self.videoView.playOrPauseButton;
     
     // 约束
     _playOrPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
     NSLayoutConstraint *playOrPauseButtonLeft = [NSLayoutConstraint constraintWithItem:_playOrPauseButton attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
     NSLayoutConstraint *playOrPauseButtonTop = [NSLayoutConstraint constraintWithItem:_playOrPauseButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeTop) multiplier:1 constant:0];
     NSLayoutConstraint *playOrPauseButtonBottom = [NSLayoutConstraint constraintWithItem:_playOrPauseButton attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
     NSLayoutConstraint *playOrPauseButtonW = [NSLayoutConstraint constraintWithItem:_playOrPauseButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
     [self.bottomToolView addConstraints:@[playOrPauseButtonLeft, playOrPauseButtonTop, playOrPauseButtonBottom, playOrPauseButtonW]];
     
     // 切换横屏按钮
     self.changeToLandscapeButton = self.videoView.changeToLandscapeButton;
     
     // 约束
     _changeToLandscapeButton.translatesAutoresizingMaskIntoConstraints = NO;
     NSLayoutConstraint *changeToLandscapeButtonTop = [NSLayoutConstraint constraintWithItem:_changeToLandscapeButton attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeTop) multiplier:1 constant:0];
     NSLayoutConstraint *changeToLandscapeButtonRight = [NSLayoutConstraint constraintWithItem:_changeToLandscapeButton attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
     NSLayoutConstraint *changeToLandscapeButtonBottom = [NSLayoutConstraint constraintWithItem:_changeToLandscapeButton attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
     NSLayoutConstraint *changeToLandscapeButtonW = [NSLayoutConstraint constraintWithItem:_changeToLandscapeButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:40];
     [self addConstraints:@[changeToLandscapeButtonTop, changeToLandscapeButtonRight, changeToLandscapeButtonBottom, changeToLandscapeButtonW]];
     
     // 视频时间
     self.videoTimeLabel = self.videoView.videoTimeLabel;
     
     // 约束
     _videoTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
     NSLayoutConstraint *videoTimeLabelRight = [NSLayoutConstraint constraintWithItem:_videoTimeLabel attribute:(NSLayoutAttributeRightMargin) relatedBy:(NSLayoutRelationEqual) toItem:_changeToLandscapeButton attribute:(NSLayoutAttributeLeft) multiplier:1 constant:-10];
     NSLayoutConstraint *videoTimeLabelCenterY = [NSLayoutConstraint constraintWithItem:_videoTimeLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
     NSLayoutConstraint *videoTimeLabelWidth = [NSLayoutConstraint constraintWithItem:_videoTimeLabel attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:90];
     [self addConstraints:@[videoTimeLabelRight, videoTimeLabelCenterY, videoTimeLabelWidth]];
     
     // 进度条
     self.progressSlider = self.videoView.progressSlider;
     
     // 约束
     _progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
     NSLayoutConstraint *sliderLeft = [NSLayoutConstraint constraintWithItem:_progressSlider attribute:(NSLayoutAttributeLeftMargin) relatedBy:(NSLayoutRelationEqual) toItem:_playOrPauseButton attribute:(NSLayoutAttributeRight) multiplier:1 constant:10];
     NSLayoutConstraint *sliderCenterY = [NSLayoutConstraint constraintWithItem:_progressSlider attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomToolView attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
     NSLayoutConstraint *sliderRight = [NSLayoutConstraint constraintWithItem:_progressSlider attribute:(NSLayoutAttributeRightMargin) relatedBy:(NSLayoutRelationEqual) toItem:_videoTimeLabel attribute:(NSLayoutAttributeLeft) multiplier:1 constant:-10];
     [self addConstraints:@[sliderLeft, sliderCenterY, sliderRight]];
     */
}

#pragma mark - 单击和双击手势
- (void)singleTap:(UITapGestureRecognizer *)tap{
    if (isFullScreen) {
        [self.videoView showOrHideBottomToolView];
        return;
    }
    
    [self changeToFullScreen];
}

- (void)doubleTap:(UITapGestureRecognizer *)tap{
    [self .videoView playOrPause:self.playOrPauseButton];
}

#pragma mark - 全屏\小窗切换
- (void)changeToFullScreen{
    
    [UIView changeInterfaceOrientation:(UIInterfaceOrientationPortrait)];
    
    _videoView.insideCloseButton.hidden = YES;
    
    [UIView animateWithDuration:0.5 animations:^{
        //        [UIView setAnimationCurve:(UIViewAnimationCurveEaseIn)];
        
        self.frame = JKScreenBounds;
        self.videoView.size = self.item.videoPortraitSize;
        self.videoView.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        [self.videoView layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        isFullScreen = YES;
        isSmallWindow = NO;
        distance = 0;
        isDragging = NO;
        [UIApplication sharedApplication].statusBarHidden = YES;
        
        [self addDoubleTap];
        [self.videoView showOrHideBottomToolView];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JKTurnOnAutoRotateNotification object:nil];
    }];
}

- (void)changeToSmallWindow{
    
    [self removeGestureRecognizer:self.doubleTap];
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    self.bottomProgressView.hidden = YES;
    
    if (self.changeToLandscapeButton.selected) {
        [self.videoView switchOrientation:self.changeToLandscapeButton];
        
        [UIView animateWithDuration:0.5 delay:0.25 options:UIViewAnimationOptionCurveLinear animations:^{
//            [UIView setAnimationCurve:(UIViewAnimationCurveEaseIn)];
            
            [self.videoView showBottomToolView:NO isShowBottomProgress:YES];
            self.size = CGSizeMake(finalWidth, finalHeight);
            self.center = FinalCenter;
            self.videoView.size = CGSizeMake(finalWidth, finalHeight);
            self.videoView.center = CGPointMake(self.width * 0.5, self.height * 0.5);
            [self.videoView layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            isFullScreen = NO;
            isSmallWindow = YES;
            distance = (FinalCenter.y - ScreenCenter.y);
            isDragging = NO;
            self.videoView.insideCloseButton.hidden = NO;
            self.bottomProgressView.hidden = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:JKTurnOffAutoRotateNotification object:nil];
        }];
        return;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
//        [UIView setAnimationCurve:(UIViewAnimationCurveEaseIn)];
        
        [self.videoView showBottomToolView:NO isShowBottomProgress:YES];
        self.size = CGSizeMake(finalWidth, finalHeight);
        self.center = FinalCenter;
        self.videoView.size = CGSizeMake(finalWidth, finalHeight);
        self.videoView.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        [self.videoView layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        isFullScreen = NO;
        isSmallWindow = YES;
        distance = (FinalCenter.y - ScreenCenter.y);
        self.videoView.insideCloseButton.hidden = NO;
        self.bottomProgressView.hidden = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JKTurnOffAutoRotateNotification object:nil];
    }];
}

#pragma mark - 滑动手势
- (void)pan:(UIPanGestureRecognizer *)pan{
    
    CGPoint cp = [pan.view convertPoint:[pan locationInView:pan.view]toView:self.bottomToolView];
    
    if ([self.bottomToolView pointInside:cp withEvent:nil] ) {
        return;
    }
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        NSLog(@"UIGestureRecognizerStateBegan");
        [self.videoView showBottomToolView:NO isShowBottomProgress:YES];
        
        self.bottomProgressView.hidden = YES;
        
        isDragging = YES;
        
        if (!self.changeToLandscapeButton.selected) {
            
            [UIApplication sharedApplication].statusBarHidden = NO;
        }
    }
    
    if (self.changeToLandscapeButton.selected) {
        return;
    }
    
    // 获取偏移
    CGPoint point = [pan translationInView:pan.view];
    
    if (!isFullScreen) {
        pan.view.centerY += point.y;
        pan.view.centerX += point.x;
        
    }else{
        
        distance += point.y;
        distance = distance < 0 ? 0 : distance;
        distance = distance > (FinalCenter.y - ScreenCenter.y) ? (FinalCenter.y - ScreenCenter.y) : distance;
        NSLog(@"distance == %.f", distance);
        
        self.videoView.height = _item.videoPortraitSize.height - (_item.videoPortraitSize.height - finalHeight) * distance / (FinalCenter.y - ScreenCenter.y);
        self.videoView.width = _item.videoPortraitSize.width - (_item.videoPortraitSize.width - finalWidth) * distance / (FinalCenter.y - ScreenCenter.y);
        
        self.height = JKScreenH - (JKScreenH - finalHeight) * distance / (FinalCenter.y - ScreenCenter.y);
        self.width = JKScreenW - (JKScreenW - finalWidth) * distance / (FinalCenter.y - ScreenCenter.y);
        
        //        self.videoView.transform = CGAffineTransformMakeScale(1 - distance / (FinalCenter.y - ScreenCenter.y) * (1 - finalWidth / JKScreenW), 1 - distance / (FinalCenter.y - ScreenCenter.y) * (1 - finalWidth / JKScreenW));
        
        
        self.videoView.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        
        
        self.centerX = ScreenCenter.x + distance / (FinalCenter.y - ScreenCenter.y) * (FinalCenter.x - ScreenCenter.x);
        self.centerY = ScreenCenter.y + distance / (FinalCenter.y - ScreenCenter.y) * (FinalCenter.y - ScreenCenter.y);
        
        NSLog(@"self.center == %@, self.videoView.center == %@", NSStringFromCGPoint(self.center), NSStringFromCGPoint(self.videoView.center));
    }
    
    // 归零
    [pan setTranslation:CGPointZero inView:pan.view];
    
    // 手势结束
    if (pan.state != UIGestureRecognizerStateEnded) return;
    
    self.bottomProgressView.hidden = NO;
    
    isDragging = NO;
    
    if (isFullScreen) {
        
        if (self.y > JKScreenH * 0.5) { // 缩小
            
            [self changeToSmallWindow];
            
        }else{
            [self changeToFullScreen];
        }
        
        return;
    }
    
    // 非全屏的情况，可以随意拖动
    if (self.centerX > JKScreenW && self.centerY >= JKScreenH * 0.5) {
        
        [self removeVideoView];
        
        return;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        
        self.centerX = (self.centerX > JKScreenW * 0.5) ? JKMaxCenterX : JKMinCenterX;
        
        self.centerY = (self.centerY > JKMaxCenterY) ? JKMaxCenterY : ((self.centerY < JKMinCenterY) ? JKMinCenterY : self.centerY);
    }];
}

- (void)removeVideoView{
    
    self.userInteractionEnabled = NO;
    [self.videoView pauseIsByUser:NO];
    
    if (isSmallWindow) {
        [UIView animateWithDuration:0.5 animations:^{
            self.alpha = 0;
            self.x = JKScreenW;
            
        } completion:^(BOOL finished) {
            [self.videoView resetPlayView];
            [self.videoView removeFromSuperview];
            self.videoView = nil;
            [self removeFromSuperview];
            vv = nil;
        }];
        return;
    }
    
    if (self.changeToLandscapeButton.selected) {
        [self.videoView switchOrientation:self.changeToLandscapeButton];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self changeToSmallWindow];
    });
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CABasicAnimation *rotation = [CABasicAnimation animation];
        rotation.keyPath = @"transform.rotation.z";
        rotation.fromValue = @(0);
        rotation.toValue = @(M_PI * 2);
        rotation.duration = 0.25;
        rotation.repeatCount = 1;
        [self.layer addAnimation:rotation forKey:nil];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeVideoView];
    });
    
    //    [UIView animateWithDuration:3 delay:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
    //        [UIView setAnimationRepeatCount:2];
    ////        self.transform = CGAffineTransformMakeRotation(M_PI - 0.001);
    ////        self.transform = CGAffineTransformRotate(CGAffineTransformMakeRotation(M_PI - 0.001), M_PI - 0.001);
    //
    //
    //        //1.围绕X轴旋转
    //        //self.myIMV.layer.transform=CATransform3DRotate(self.myIMV.layer.transform, M_PI/60, 1, 0, 0);
    //        //2.围绕Y轴旋转
    //        //self.myIMV.layer.transform=CATransform3DRotate(self.myIMV.layer.transform, M_PI/60, 0, 1, 0);
    //        //3.围绕Z轴旋转
    ////        self.layer.transform = CATransform3DRotate(self.layer.transform, M_PI * 2, 0, 0, 1);
    //
    //
    //
    //    } completion:^(BOOL finished) {
    //
    //        self.transform = CGAffineTransformIdentity;
    //        [self removeVideoView];
    //    }];
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JKTurnOffAutoRotateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end


