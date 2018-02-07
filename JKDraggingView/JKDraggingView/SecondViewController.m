//
//  SecondViewController.m
//  JKDraggingView
//
//  Created by albert on 2017/3/21.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "SecondViewController.h"
#import "UIView+JKExtension.h"
#import "JKDraggingVideoView.h"

@interface SecondViewController ()
/** <#注释#> */
@property (nonatomic, weak) JKDraggingVideoView *draggingVideoView ;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)wangnima:(id)sender {
    JKDraggingVideoItem *item = [[JKDraggingVideoItem alloc] init];
    
    item.videoUrl = @"http://wvideo.spriteapp.cn/video/2017/0317/58cb1ba0ef10f_wpd.mp4";
    item.videoOriginalSize = CGSizeMake(640, 360);
    [JKDraggingVideoView showWithItem:item];
}

- (IBAction)pipiXia:(id)sender {
    JKDraggingVideoItem *item = [[JKDraggingVideoItem alloc] init];
    
    item.videoUrl = @"http://wvideo.spriteapp.cn/video/2017/0316/58ca1d7a66750_wpd.mp4";
    item.videoOriginalSize = CGSizeMake(480, 640);
    [JKDraggingVideoView showWithItem:item];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
//    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
//        return self.draggingVideoView;
//    }
//    return YES;
//}

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
