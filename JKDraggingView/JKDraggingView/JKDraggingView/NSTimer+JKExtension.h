//
//  NSTimer+JKExtension.h
//  JKWheels
//
//  Created by albert on 2017/3/8.
//  Copyright © 2017年 安永博. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (JKExtension)
+ (NSTimer *)jk_scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats isFire:(BOOL)isFire timerBlock:(void(^)(void))timerBlock;

- (void)jk_pauseTimer;
- (void)jk_resumeTimer;
- (void)jk_resumeTimerAfterTimeInterval:(NSTimeInterval)interval;
@end
