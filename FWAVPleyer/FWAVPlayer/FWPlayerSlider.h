//
//  FWPlayerSlider.h
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FWPlayerSliderDragDelegate <NSObject>


/**
 *  开始拖动进度
 */
- (void)playerSliderBeginDragProgress;

/**
 *  拖动进度
 *
 *  @param progress 进度
 */
- (void)playerSliderDragingProgress:(CGFloat)progress;

/**
 *  结束拖动
 */
- (void)playerSliderEndDragProgress;

@end

@interface FWPlayerSlider : UIView

@property (weak,nonatomic)id<FWPlayerSliderDragDelegate>dragDelegate;

/**
 *  观看进度
 */
@property (assign, nonatomic)CGFloat topProgress;
/**
 *  缓存进度
 */
@property (assign, nonatomic)CGFloat midProgress;
/**
 *  fps图片
 */
@property (nonatomic, strong) UIImageView *fpsImageView;

@end
