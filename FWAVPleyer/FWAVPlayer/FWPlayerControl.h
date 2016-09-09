//
//  FWPlayerControl.h
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MPVolumeView.h>
#import "FWAVPlayerManager.h"
#import <Masonry.h>


@interface FWPlayerControl : UIView

@property (strong,nonatomic)NSString *videoUrl;

@property (strong,nonatomic)UIView *playerView;

@property (strong, nonatomic) FWAVPlayerManager* playerManager;//播放器

/**
 *  禁止滑动控制 default NO/可用
 */
@property (assign,nonatomic)BOOL isDisableDrag;

/**
 *  开始拖动进度
 */
- (void)beginDragProgress;

/**
 *  拖动进度
 *
 *  @param progress 进度
 */
- (void)dragingProgress:(CGFloat)progress;

/**
 *  结束拖动
 */
- (void)endDragProgress;

@end
