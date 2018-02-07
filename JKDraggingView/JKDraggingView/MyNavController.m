//
//  MyNavController.m
//  JKDraggingView
//
//  Created by albert on 2017/3/21.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "MyNavController.h"
#import "AppDelegate.h"
#import "JKDraggingVideoViewMacro.h"

@interface MyNavController ()

/** 是否允许自动旋转 */
@property (nonatomic, assign) BOOL canAutoRotate;
@end

@implementation MyNavController

+ (void)initialize{
    [UINavigationBar appearance].barTintColor = [UIColor orangeColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canRotate) name:JKTurnOnAutoRotateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canNotRotate) name:JKTurnOffAutoRotateNotification object:nil];
}

- (void)canRotate{
    
    self.canAutoRotate = YES;
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate setIsCanAutoRotate:YES];
    
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    } else {
        // Fallback on earlier versions
    }
}

- (void)canNotRotate{
    
    self.canAutoRotate = NO;
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate setIsCanAutoRotate:NO];
    
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    } else {
        // Fallback on earlier versions
    }
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden{
    return nil;
}

- (BOOL)shouldAutorotate{
    return self.canAutoRotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return self.canAutoRotate ? UIInterfaceOrientationMaskPortrait |UIInterfaceOrientationMaskLandscapeRight : UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return self.canAutoRotate ? UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait ;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
