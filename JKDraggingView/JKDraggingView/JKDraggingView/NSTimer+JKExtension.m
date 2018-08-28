//
//  NSTimer+JKExtension.m
//  JKWheels
//
//  Created by albert on 2017/3/8.
//  Copyright © 2017年 安永博. All rights reserved.
//

#import "NSTimer+JKExtension.h"

@implementation NSTimer (JKExtension)
+ (NSTimer *)jk_scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats isFire:(BOOL)isFire timerBlock:(void(^)(void))timerBlock{
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(jk_timerBlockInvoke:) userInfo:[timerBlock copy] repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    if (isFire) {
        [timer fire];
    }
    
    return timer;
    
//    return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(jk_timerBlockInvoke:) userInfo:[timerBlock copy] repeats:repeats];
}

+ (void)jk_timerBlockInvoke:(NSTimer *)timer{
    
    void(^block)(void) = timer.userInfo;
    
    !block ? :  block();
}

- (void)jk_pauseTimer{
    if (![self isValid]) {
        return ;
    }
    [self setFireDate:[NSDate distantFuture]];
}


- (void)jk_resumeTimer{
    if (![self isValid]) {
        return ;
    }
    [self setFireDate:[NSDate date]];
}

- (void)jk_resumeTimerAfterTimeInterval:(NSTimeInterval)interval{
    if (![self isValid]) {
        return ;
    }
    [self setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
}
@end
