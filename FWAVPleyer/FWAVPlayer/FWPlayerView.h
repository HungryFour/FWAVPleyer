//
//  FWPlayerView.h
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import "FWPlayerControl.h"
#import "FWAVPlayerManager.h"

typedef NS_ENUM(NSInteger,kDeviceOrientation) {

    kDeviceOrientationPortrait = 0,                 //Home键在底部
    kDeviceOrientationPortraitUpsideDown,           //Home键在顶部
    kDeviceOrientationLandscapeLeft,                //Home键在右边
    kDeviceOrientationLandscapeRight,               //Home键在左边
};
@class FWPlayerView;

@protocol FWPlayerViewStateDelegate <NSObject>

- (void)playerView:(FWPlayerView *)playerView state:(FWAVPlayerPlayState)state;

@end

@interface FWPlayerView : FWPlayerControl

@property (weak,nonatomic) id<FWPlayerViewStateDelegate>stateDelegate;

/**
 *  更新PlayerView的约束
 */
- (void)updatePlayerViewConstraints;
/**
 *  占位图
 */
@property (strong,nonatomic)UIImageView *placeholderImageView;
/**
 *  小窗口模式
 */
@property (assign,nonatomic) BOOL isMini;

/**
 *  播放结束后自动清除
 */
@property (assign,nonatomic) BOOL isClearFinished;
/**
 *  播放器状态
 */
@property (assign,nonatomic) FWAVPlayerPlayState state;
/**
 *  是否全屏
 */
@property (nonatomic, assign) BOOL isFullscreenMode;

/**
 *  是否开启旋转锁  默认YES/关闭锁 开启后视频会根据手机旋转而旋转
 */
@property (nonatomic, assign) BOOL rotationLock;


@end
