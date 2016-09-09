//
//  PlayerViewController.m
//  FWAVPlayerDemo
//
//  Created by 武建明 on 16/9/7.
//  Copyright © 2016年 Four_w. All rights reserved.
//

#import "PlayerViewController.h"

#import "FWAVPlayerManager.h"
#import "FWPlayerView.h"
#import <UIImageView+WebCache.h>

#define kSMainWidth [UIScreen mainScreen].bounds.size.width
#define kSMainHeight [UIScreen mainScreen].bounds.size.height
#define kNavViewHeight 64
#define kVideoViewHeight kSMainWidth*(9.0/16.0)
#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

@interface PlayerViewController ()<FWPlayerViewStateDelegate>

@property (strong,nonatomic)FWPlayerView *playerView;

@property (strong,nonatomic)UIButton *returnButton;//返回

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.playerView];
    [self.view addSubview:self.returnButton];

    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.size.mas_equalTo(CGSizeMake(kSMainWidth, kVideoViewHeight));
    }];

    [self.returnButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.size.mas_equalTo(CGSizeMake(44, 60));
    }];

    [self.playerView.placeholderImageView sd_setImageWithURL:[NSURL URLWithString:self.videoModel.img]];
    self.playerView.videoUrl = self.videoModel.video;
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.playerView.playerManager clear];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.playerView.rotationLock = NO;
}
- (BOOL)shouldAutorotate{
    return NO;
}
- (UIButton *)returnButton
{
    if (!_returnButton) {
        _returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _returnButton.backgroundColor = [UIColor clearColor];
        [_returnButton setTitle:@"返回" forState:UIControlStateNormal];
        [_returnButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_returnButton addTarget:self action:@selector(returnButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _returnButton.selected = NO;
    }
    return _returnButton;
}
- (FWPlayerView *)playerView{
    if (!_playerView) {
        _playerView = [[FWPlayerView alloc]init];
        _playerView.backgroundColor = [UIColor lightGrayColor];
        _playerView.stateDelegate = self;
        _playerView.isClearFinished = NO;
    }
    return _playerView;
}
#pragma Mark- Action
- (void)returnButtonClick{
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}
#pragma mark - FWPlayerViewStateDelegate
- (void)playerView:(FWPlayerView *)playerView state:(FWAVPlayerPlayState)state{

    switch (state) {

        case FWAVPlayerPlayStatePlaying:
            NSLog(@"FWAVPlayerPlayStatePlaying");

            break;
        case FWAVPlayerPlayStatePause:
            NSLog(@"FWAVPlayerPlayStatePause");

            break;
        case FWAVPlayerPlayStateFinished:
            NSLog(@"FWAVPlayerPlayStateFinished");

            break;
        case FWAVPlayerPlayStateBuffering:
            NSLog(@"FWAVPlayerPlayStateBuffering");

            break;
        case FWAVPlayerPlayStateFailed:
            NSLog(@"FWAVPlayerPlayStateFailed");

            break;

        default:
            break;
    }
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
