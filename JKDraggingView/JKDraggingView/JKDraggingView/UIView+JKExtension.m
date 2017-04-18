//
//  UIView+JKExtension.m
//  01-百思不得姐
//
//  Created by albert on 16/3/13.
//  Copyright (c) 2016年 albert. All rights reserved.
//

#import "UIView+JKExtension.h"
#import <objc/message.h>
#import <AVFoundation/AVFoundation.h>

@implementation UIView (JKExtension)

- (void)setCenterX:(CGFloat)centerX{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (void)setCenterY:(CGFloat)centerY{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGFloat)centerX{
    return self.center.x;
}

- (CGFloat)centerY{
    return self.center.y;
}

- (void)setSize:(CGSize)size{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGSize)size{
    return self.frame.size;
}

- (void)setWidth:(CGFloat)width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (void)setX:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)width{
    return self.frame.size.width;
}

- (CGFloat)height{
    return self.frame.size.height;
}

- (CGFloat)x{
    return self.frame.origin.x;
}

- (CGFloat)y{
    return self.frame.origin.y;
}

/** 判断控件是否真正显示在窗口范围内 */
- (BOOL)isShowingOnKeyWindow{
    //主窗口
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    //得到self在主窗口中的frame
    // 转换self的frame，写成nil就是转为以屏幕左上角为原点
    //CGRect newFrame = [self.superview convertRect:subview.frame toView:nil];
    CGRect newFrame = [keyWindow convertRect:self.frame fromView:self.superview];
    
    //窗口的bounds
    CGRect windowBounds = keyWindow.bounds;
    
    //主窗口的bounds 和 subview主窗口左上角为原点的frame 是否有重叠
    // CGRectIntersectsRect(newFrame, windowBounds)比较两个rect是否有交叉
    BOOL intersects = CGRectIntersectsRect(newFrame, windowBounds);
    
    //返回。控件没有被添加到窗口上时，控件的window == nil
    return !self.hidden && self.alpha > 0.01 && intersects && self.window == keyWindow;
}

/** 从xib中加载view */
+ (instancetype)viewFromXib{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

/** 切换横竖屏 */
+ (void)changeInterfaceOrientation:(UIInterfaceOrientation)orientation{
    
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

/*
+ (void)load
{
    SEL originalSelector = @selector(actionForLayer:forKey:);
    SEL extendedSelector = @selector(DR_actionForLayer:forKey:);
    
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method extendedMethod = class_getInstanceMethod(self, extendedSelector);
    
    NSAssert(originalMethod, @"original method should exist");
    NSAssert(extendedMethod, @"exchanged method should exist");
    
    if(class_addMethod(self, originalSelector, method_getImplementation(extendedMethod), method_getTypeEncoding(extendedMethod))) {
        class_replaceMethod(self, extendedSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, extendedMethod);
    }
}

static void *DR_currentAnimationContext = NULL;
static void *DR_popAnimationContext     = &DR_popAnimationContext;

- (id<CAAction>)DR_actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if ([layer isKindOfClass:[AVPlayerLayer class]]) {
        // 这里写我们自定义的代码...
        return [[NSNull alloc] init];
    }
    
    // 调用原始方法
    return [self DR_actionForLayer:layer forKey:event]; // 没错，你没看错。因为它们已经被交换了
}*/
/*
+ (void)DR_popAnimationWithDuration:(NSTimeInterval)duration
                         animations:(void (^)(void))animations
{
    DR_currentAnimationContext = DR_popAnimationContext;
    // 执行动画 (它将触发交换后的 delegate 方法)
    animations();*/
    /* 一会儿再添加 *//*
    DR_currentAnimationContext = NULL;
} */
@end
