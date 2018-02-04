//
//  JKDraggingVideoViewMacro.h
//  JKDraggingView
//
//  Created by albert on 2018/2/3.
//  Copyright © 2018年 albert. All rights reserved.
//

#ifndef JKDraggingVideoViewMacro_h
#define JKDraggingVideoViewMacro_h




#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds



#define JKMaxCenterX (JKScreenW - self.item.screenInsets.right - self.width * 0.5)
#define JKMaxCenterY (JKScreenH - self.item.screenInsets.bottom - self.height * 0.5)

#define JKMinCenterX (self.item.screenInsets.left + self.width * 0.5)
#define JKMinCenterY (self.item.screenInsets.top + self.height * 0.5)


#define JKIsIphoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)



/** 开启自动旋转 通知名字 */
#define JKTurnOnAutoRotateNotification  @"JKTurnOnAutoRotateNotification"

/** 关闭自动旋转 通知名字 */
#define JKTurnOffAutoRotateNotification  @"JKTurnOffAutoRotateNotification"







#endif /* JKDraggingVideoViewMacro_h */
