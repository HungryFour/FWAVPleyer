//
//  FWAVPlayerManager.h
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger,FWAVPlayerPlayState) {

    FWAVPlayerPlayStatePlaying = 0x0,     // 正在播放
    FWAVPlayerPlayStatePause,             // 播放暂停
    FWAVPlayerPlayStateFinished,          // 播放结束
    FWAVPlayerPlayStateBuffering,         // 缓冲中
    FWAVPlayerPlayStateFailed,            // 播放失败
};
typedef NS_ENUM(NSInteger,FWAVPlayerPlaySlideState) {

    FWAVPlayerPlaySlideStateBegin = 0x0,      // 开始拖动
    FWAVPlayerPlaySlideStateSliding,          // 拖动中
    FWAVPlayerPlaySlideStateEnd,              // 拖动结束
};

typedef NS_ENUM(NSInteger, FWPlayerVideoFillMode) {
    FWPlayerVideoFillModeResize,           // 非均匀模式。两个维度完全填充至整个视图区域
    FWPlayerVideoFillModeResizeAspect,     // 等比例填充，直到一个维度到达区域边界
    FWPlayerVideoFillModeResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
};

/**
 *  获取播放的进度
 */
typedef void (^FWProgressBlock)(CGFloat progress);

/**
 *  获得已经加载的百分比
 */
typedef void (^FWLoadingPercentageBlock)(CGFloat loadingPercentage);

/**
 *  视频播放状态
 */
typedef void (^FWStatusBlock)(FWAVPlayerPlayState status);

/**
 *  视频拖动状态
 */
typedef void (^FWSlideStateBlock)(FWAVPlayerPlaySlideState state);

/**
 *  滑动时返回帧图片
 */
typedef void (^FWSliderFPSImageBlock)(UIImage *fpsImage);

@interface FWAVPlayerManager : NSObject


- (instancetype)initOnView:(UIView *)superView;

/**
 *  开始拖动
 */
- (void)beginSliderDrag;
/**
 *  结束拖动
 */
- (void)endSliderDrag;
/**
 *  拖动值发生改变
 *
 *  @param time 跳转的时间点 秒计数
 */
- (void)sliderSeekToTime:(CGFloat)time;

/**
 *  拖动值发生改变
 *
 *  @param time 跳转的百分比
 */
- (void)sliderSeekToProgress:(CGFloat)progress;

/**
 *  播放
 */
- (void)play;
/**
 *  暂停
 */
- (void)pause;
/**
 *  重播
 */
- (void)resum;
/**
 *  清除
 */
- (void)clear;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;

/**
 *  是否在播放
 */
@property (nonatomic, assign, readonly) BOOL isPlaying;

/**
 *  视频地址
 */
@property (strong, nonatomic)NSURL *url;

/**
 *  父视图
 */
@property (strong, nonatomic)UIView *superView;

/**
 *  当前播放时间CMTime
 */
@property (assign, nonatomic)CMTime currentDuration;

/**
 *  当前播放时间Str //返回样式00:00:00
 */
@property (strong, nonatomic)NSString *currentDurationString;

/**
 *  视频总时长CMTime
 */
@property (assign, nonatomic)CMTime itemDuration;

/**
 *  视频总时长Str //返回样式 00:00:00
 */
@property (strong, nonatomic)NSString *itemDurationString;

/**
 *  视频填充方式
 */
@property (assign, nonatomic)FWPlayerVideoFillMode fillMode;

/**
 *  获取播放的进度
 */
@property (copy, nonatomic)FWProgressBlock progress;

/**
 *  视频拖动状态
 */
@property (copy, nonatomic)FWSlideStateBlock slideState;

/**
 *  获得已经加载的百分比
 */
@property (copy, nonatomic)FWLoadingPercentageBlock loadingPercentage;

/**
 *  视频播放状态
 */
@property (copy, nonatomic)FWStatusBlock status;

/**
 *  滑动时返回帧图片
 */
@property (copy, nonatomic)FWSliderFPSImageBlock fpsImage;

/**
 *  当前帧图片
 */
- (void)currentImage:(void (^)(UIImage *))currentImageBlock;

/**
 *  Video来源
 */
@property (assign, nonatomic)BOOL isNetUrl;

@end
