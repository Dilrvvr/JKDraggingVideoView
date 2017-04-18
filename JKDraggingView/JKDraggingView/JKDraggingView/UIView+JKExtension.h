//
//  UIView+JKExtension.h
//  01-百思不得姐
//
//  Created by albert on 16/3/13.
//  Copyright (c) 2016年 albert. All rights reserved.
//

#import <UIKit/UIKit.h>

#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds

@interface UIView (JKExtension)
/** 尺寸 */
@property (nonatomic,assign) CGSize size;
/** 宽度 */
@property (nonatomic,assign) CGFloat width;
/** 高度 */
@property (nonatomic,assign) CGFloat height;
/** X */
@property (nonatomic,assign) CGFloat x;
/** Y */
@property (nonatomic,assign) CGFloat y;
/** centerX */
@property (nonatomic,assign) CGFloat centerX;
/** centerY */
@property (nonatomic,assign) CGFloat centerY;

//注意：在分类中声明@property，只会生成方法的声明，不会生成方法的实现和带有_下划线的成员变量

/** 判断控件是否真正显示在窗口范围内 */
- (BOOL)isShowingOnKeyWindow;

/** 从xib中加载view */
+ (instancetype)viewFromXib;

/** 切换横竖屏 */
+ (void)changeInterfaceOrientation:(UIInterfaceOrientation)orientation;
@end
