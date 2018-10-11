//
//  MyViewController.m
//  JKDraggingView
//
//  Created by albert on 2017/3/21.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "MyViewController.h"
#import "AppDelegate.h"
#import "JKDraggingVideoViewMacro.h"

@interface MyViewController ()

@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canRotate) name:JKDraggingVideoTurnOnAutoRotateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canNotRotate) name:JKDraggingVideoTurnOffAutoRotateNotification object:nil];
}

- (void)canRotate{
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate setIsCanAutoRotate:YES];
    
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    } else {
        // Fallback on earlier versions
    }
}

- (void)canNotRotate{
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate setIsCanAutoRotate:NO];
    
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    } else {
        // Fallback on earlier versions
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate{
    return NO;
}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
//    return UIInterfaceOrientationMaskPortrait;
//}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
