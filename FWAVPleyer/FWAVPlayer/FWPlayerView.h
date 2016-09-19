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

//@protocol FWPlayerViewIsFullscreenModeDelegate <NSObject>
//
///**
// 屏幕全屏半屏状态切换通知
//
// @param playerView       playerView
// @param isFullscreenMode 是否是全屏状态
// */
//- (void)playerView:(FWPlayerView *)playerView isFullscreenMode:(BOOL)isFullscreenMode;
//@end

@protocol FWPlayerViewStateDelegate <NSObject>

/**
 播放状态代理通知

 @param playerView player
 @param state      播放状态
 */
- (void)playerView:(FWPlayerView *)playerView state:(FWAVPlayerPlayState)state;
@end

@interface FWPlayerView : FWPlayerControl

@property (weak,nonatomic) id<FWPlayerViewStateDelegate>stateDelegate;

//@property (weak,nonatomic) id<FWPlayerViewIsFullscreenModeDelegate>isFullscreenModeDelegate;

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
@property (nonatomic, assign, readonly) BOOL isFullscreenMode;

/**
    检测屏幕方向的观察者是否存在,默认存在, 置为YES时,横屏竖屏,视频窗口跟随变化
 */
@property (nonatomic, assign)BOOL hasDeviceOrientationObserver;

/**
    是否允许自动旋转屏幕,锁屏时用
 */
@property (assign, nonatomic, readonly)BOOL shouldAutorotate;

/**
    屏幕旋转,当前方向
 */
@property (assign, nonatomic, readonly)UIInterfaceOrientationMask interfaceOrientationMask;

@end
