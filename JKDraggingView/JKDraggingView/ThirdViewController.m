//
//  ThirdViewController.m
//  JKDraggingView
//
//  Created by albert on 2017/3/20.
//  Copyright © 2017年 albert. All rights reserved.
//

#import "ThirdViewController.h"
#import "JKDraggingVideoView.h"

@interface ThirdViewController ()

@end

@implementation ThirdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)shitChen:(id)sender {
    JKDraggingVideoItem *item = [[JKDraggingVideoItem alloc] init];
    
    item.videoUrl = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2018/0828/5b84fb33cd43f_wpd.mp4"];//@"http://wvideo.spriteapp.cn/video/2017/0319/58ce61d9c0fbd_wpd.mp4"];
    item.videoOriginalSize = CGSizeMake(854, 480);
    [JKDraggingVideoView showWithItem:item];
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
