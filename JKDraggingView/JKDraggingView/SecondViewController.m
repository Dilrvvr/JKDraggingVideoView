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
#import <AVFoundation/AVFoundation.h>

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
    
    item.videoUrl = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2018/0828/4c33546eaa6a11e8bc74842b2b4c75ab_wpd.mp4"];//@"http://wvideo.spriteapp.cn/video/2017/0317/58cb1ba0ef10f_wpd.mp4"];
    item.videoOriginalSize = CGSizeMake(848, 480);
    [JKDraggingVideoView showWithItem:item];
}

- (IBAction)pipiXia:(id)sender {
    JKDraggingVideoItem *item = [[JKDraggingVideoItem alloc] init];
    
    item.videoUrl = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2018/0828/1c45c844-aa25-11e8-a652-1866daeb0df1_wpd.mp4"];//@"http://wvideo.spriteapp.cn/video/2017/0316/58ca1d7a66750_wpd.mp4"];
    item.videoOriginalSize = CGSizeMake(852, 480);
    [JKDraggingVideoView showWithItem:item];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:item.videoUrl options:nil];
    [self getVideoSize:asset];
}



// 获取视频的尺寸
- (void)getVideoSize:(AVAsset *)asset{
    
    // 一般视频都有至少两个track(轨道)，根据track.mediaType判断track类型
    // AVMediaTypeVideo表示视频轨道，AVMediaTypeAudio代表音频轨道，其他类型可以查看文档。
    // 根据track的naturalSize属性即可获得视频尺寸
    NSArray *array = asset.tracks;
    
    for (AVAssetTrack *track in array) {
        
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            // 注意naturalSize的宽高是反着的
            CGSize videoSize = CGSizeMake(track.naturalSize.height, track.naturalSize.width);
            NSLog(@"videoSize -->%@", NSStringFromCGSize(videoSize));
            break;
        }
    }
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
