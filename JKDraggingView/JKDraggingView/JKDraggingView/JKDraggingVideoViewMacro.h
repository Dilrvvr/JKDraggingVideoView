//
//  JKDraggingVideoViewMacro.h
//  JKDraggingView
//
//  Created by albert on 2018/2/3.
//  Copyright © 2018年 albert. All rights reserved.
//

#ifndef JKDraggingVideoViewMacro_h
#define JKDraggingVideoViewMacro_h




#define JKDraggingVideoScreenW [UIScreen mainScreen].bounds.size.width
#define JKDraggingVideoScreenH [UIScreen mainScreen].bounds.size.height
#define JKDraggingVideoScreenBounds [UIScreen mainScreen].bounds



#define JKDraggingVideoMaxCenterX (JKDraggingVideoScreenW - self.item.screenInsets.right - self.width * 0.5)
#define JKDraggingVideoMaxCenterY (JKDraggingVideoScreenH - self.item.screenInsets.bottom - self.height * 0.5)

#define JKDraggingVideoMinCenterX (self.item.screenInsets.left + self.width * 0.5)
#define JKDraggingVideoMinCenterY (self.item.screenInsets.top + self.height * 0.5)



/** 开启自动旋转 通知名字 */
#define JKDraggingVideoTurnOnAutoRotateNotification  @"JKDraggingVideoTurnOnAutoRotateNotification"

/** 关闭自动旋转 通知名字 */
#define JKDraggingVideoTurnOffAutoRotateNotification  @"JKDraggingVideoTurnOffAutoRotateNotification"







#endif /* JKDraggingVideoViewMacro_h */
