//
//  JKDraggingView.m
//  JKDraggingView
//
//  Created by albert on 2017/3/18.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "JKDraggingView.h"
#import "UIView+JKExtension.h"

#define JKMargin 10
#define JKMaxCenterX (JKScreenW - JKMargin - self.width * 0.5)
#define JKMaxCenterY (JKScreenH - JKMargin - self.height * 0.5)

#define JKMinCenterX (JKMargin + self.width * 0.5)
#define JKMinCenterY (JKMargin + self.height * 0.5)

@interface JKDraggingView () {
    CGPoint FinalCenter;
    CGPoint ScreenCenter;
}

@end

@implementation JKDraggingView

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
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    isFullScreen = (self.width >= JKScreenW && self.height >= JKScreenH);
    
    distance = 0;
    FinalCenter = CGPointMake(JKScreenW - finalWidth * 0.5 - JKMargin, JKScreenH - finalHeight * 0.5 - JKMargin);
    ScreenCenter = CGPointMake(JKScreenW * 0.5, JKScreenH * 0.5);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
}

- (void)tap:(UITapGestureRecognizer *)tap{
    if (isFullScreen) {
        return;
    }
    
    [self changeToFullScreen];
}

- (void)changeToFullScreen{
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = JKScreenBounds;
        
    } completion:^(BOOL finished) {
        isFullScreen = YES;
        distance = 0;
    }];
}

- (void)changeToSmallWindow{
    [UIView animateWithDuration:0.25 animations:^{
        
        self.size = CGSizeMake(finalWidth, finalHeight);
        self.center = FinalCenter;
        
    } completion:^(BOOL finished) {
        isFullScreen = NO;
        distance = (FinalCenter.y - ScreenCenter.y);
    }];
}

static BOOL isFullScreen = NO;

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
}

static CGFloat const finalWidth = 160;
static CGFloat const finalHeight = 90;

static CGFloat distance = 0;

- (void)pan:(UIPanGestureRecognizer *)pan{
    if (pan.state == UIGestureRecognizerStateBegan) {
        NSLog(@"UIGestureRecognizerStateBegan");
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
        
        self.height = JKScreenH - (JKScreenH - finalHeight) * distance / (FinalCenter.y - ScreenCenter.y);
        self.width = JKScreenW - (JKScreenW - finalWidth) * distance / (FinalCenter.y - ScreenCenter.y);
        
        self.centerX = ScreenCenter.x + distance / (FinalCenter.y - ScreenCenter.y) * (FinalCenter.x - ScreenCenter.x);
        self.centerY = ScreenCenter.y + distance / (FinalCenter.y - ScreenCenter.y) * (FinalCenter.y - ScreenCenter.y);
    }
    
    // 归零
    [pan setTranslation:CGPointZero inView:pan.view];
    
    
    // 手势结束
    if (pan.state != UIGestureRecognizerStateEnded) return;
    
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
        
        [UIView animateWithDuration:0.5 animations:^{
            self.alpha = 0;
            self.x = JKScreenW;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
        
        return;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        
        self.centerX = (self.centerX > JKScreenW * 0.5) ? JKMaxCenterX : JKMinCenterX;
        
        self.centerY = (self.centerY > JKMaxCenterY) ? JKMaxCenterY : ((self.centerY < JKMinCenterY) ? JKMinCenterY : self.centerY);
    }];
}

- (void)dealloc{
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
