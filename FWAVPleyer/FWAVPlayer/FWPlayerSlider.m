//
//  FWPlayerSlider.m
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import "FWPlayerSlider.h"
#import <Masonry.h>
#import "FWAVPlayer.h"

static const CGFloat kPlayerSliderHeight = 30.0;//高度

@interface FWPlayerSlider ()

@property (assign, nonatomic) BOOL isDirectionLeftOrRight;

@property (assign, nonatomic) CGPoint startPoint;

@property (assign, nonatomic) CGPoint sliderStartCenter;

//表层
@property (nonatomic, strong) UIView *topShapeView;
//中层
@property (nonatomic, strong) UIView *midShapeView;
//底层
@property (nonatomic, strong) UIView *bottomShapeView;
//底层
@property (nonatomic, strong) UIImageView *sliderImageView;
@end

@implementation FWPlayerSlider{
    BOOL isBeiginSliderDrag;
}

- (instancetype)initWithFrame:(CGRect)frame{

    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.isDirectionLeftOrRight = NO;

        [self addViews];
        [self setConstraints];

        self.topProgress = 0;
        self.midProgress = 0;

    }
    return self;

}
- (instancetype)init{
    self = [super init];
    if (self) {
        self.clipsToBounds = NO;
        self.isDirectionLeftOrRight = NO;


        [self addViews];
        [self setConstraints];

        self.topProgress = 0;
        self.midProgress = 0;
    }
    return self;
}
- (void)addViews{

    [self addSubview:self.bottomShapeView];
    [self addSubview:self.midShapeView];
    [self addSubview:self.topShapeView];
    [self addSubview:self.sliderImageView];
    [self addSubview:self.fpsImageView];

    [self insertSubview:self.bottomShapeView atIndex:0];
    [self insertSubview:self.midShapeView atIndex:1];
    [self insertSubview:self.topShapeView atIndex:2];
    [self insertSubview:self.sliderImageView atIndex:3];

}
- (void)layoutSubviews{
    [super layoutSubviews];

    [self.topShapeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.bounds.size.width*_topProgress);
        make.centerY.equalTo(self.mas_centerY);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(2);
    }];

    [self.midShapeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.bounds.size.width*_midProgress);
        make.centerY.equalTo(self.mas_centerY);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(2);
    }];
}
#pragma mark - property
- (UIView *)topShapeView
{
    if (!_topShapeView) {
        _topShapeView = [[UIView alloc]init];
        _topShapeView.backgroundColor = [UIColor whiteColor];
    }
    return _topShapeView;
}
- (UIView *)midShapeView
{
    if (!_midShapeView) {
        _midShapeView = [[UIView alloc]init];
        _midShapeView.backgroundColor = [UIColor colorWithRed:0.66 green:0.66 blue:0.66 alpha:1];
    }
    return _midShapeView;
}
- (UIView *)bottomShapeView
{
    if (!_bottomShapeView) {
        _bottomShapeView = [[UIView alloc]init];
        _bottomShapeView.backgroundColor = [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1];
    }
    return _bottomShapeView;
}
- (UIImageView *)sliderImageView{
    if (!_sliderImageView) {
        _sliderImageView = [[UIImageView alloc]init];
        _sliderImageView.backgroundColor = [UIColor clearColor];
        _sliderImageView.image = FWAVPlayerImage(@"fw-player-point");
        _sliderImageView.userInteractionEnabled = NO;
        _sliderImageView.contentMode = UIViewContentModeCenter;
    }
    return _sliderImageView;
}
- (UIImageView *)fpsImageView{
    if (!_fpsImageView) {
        _fpsImageView = [[UIImageView alloc]init];
        _fpsImageView.backgroundColor = [UIColor clearColor];
        _fpsImageView.userInteractionEnabled = NO;
        _fpsImageView.hidden = YES;
    }
    return _fpsImageView;
}
- (void)setConstraints{

    [self.topShapeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(2);
        make.width.mas_equalTo(0);
    }];
    self.topShapeView.mas_key = @"topShapeView";

    [self.sliderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.centerX.mas_equalTo(self.topShapeView.mas_right);
        make.height.equalTo(self.mas_height);
        make.width.equalTo(self.mas_height);
    }];
    self.sliderImageView.mas_key = @"sliderImageView";

    [self.fpsImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_top);
        make.centerX.mas_equalTo(self.topShapeView.mas_right);
        make.height.equalTo(@90);
        make.width.equalTo(@180);
    }];
    self.fpsImageView.mas_key = @"fpsImageView";

    [self.midShapeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(2);
        make.width.mas_equalTo(0);
    }];
    self.midShapeView.mas_key = @"midShapeView";

    [self.bottomShapeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(2);
    }];
    self.bottomShapeView.mas_key = @"bottomShapeView";

}
#pragma mark - set
- (void)setTopProgress:(CGFloat)topProgress{
    _topProgress = topProgress >=0 ? topProgress : 0;
    [self.topShapeView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.bounds.size.width*_topProgress);
    }];
    // 约束需要更新
    [self setNeedsUpdateConstraints];
    // 调用此方法告诉self检测是否需要更新约束，若需要则更新，下面添加动画效果才起作用
    [self layoutIfNeeded];

}
- (void)setMidProgress:(CGFloat)midProgress{
    _midProgress = midProgress >=0 ? midProgress : 0;
    [self.midShapeView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.bounds.size.width*_midProgress);
    }];
    // 约束需要更新
    [self setNeedsUpdateConstraints];
    // 调用此方法告诉self检测是否需要更新约束，若需要则更新，下面添加动画效果才起作用
    [self layoutIfNeeded];
}
//触摸开始
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //获取触摸开始的坐标
    UITouch *touch = [touches anyObject];
    self.startPoint = [touch locationInView:self];
    self.sliderStartCenter = self.sliderImageView.center;
    [self touchesBegan];
}

//触摸结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnd];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self touchesEnd];
}
//移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentP = [touch locationInView:self];
    [self touchesMoveWithPoint:currentP];
}

#pragma mark - 开始触摸
- (void)touchesBegan {
    isBeiginSliderDrag = YES;
}
#pragma mark - 结束触摸
- (void)touchesEnd{
    if (self.dragDelegate) {
        [self.dragDelegate playerSliderEndDragProgress];
    }
}
#pragma mark - 拖动
- (void)touchesMoveWithPoint:(CGPoint)point {
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x,self.startPoint.y);
    //分析出用户滑动的方向
    if (!self.isDirectionLeftOrRight) {
        if (panPoint.x >= kPlayerSliderHeight || panPoint.x <= -kPlayerSliderHeight) {
            self.isDirectionLeftOrRight = YES;
        } else if (panPoint.y >= kPlayerSliderHeight || panPoint.y <= -kPlayerSliderHeight) {
            self.isDirectionLeftOrRight = NO;
        }
    }
    if (!self.isDirectionLeftOrRight) {
        return;
    }else{
        //如果为正,则说明是第一次滑动
        if (isBeiginSliderDrag) {
            if (self.dragDelegate) {
                [self.dragDelegate playerSliderBeginDragProgress];
            }
        }
        isBeiginSliderDrag = NO;

        //进度
        CGFloat rate = (panPoint.x+self.sliderStartCenter.x)/self.bounds.size.width;

        if (rate > 1) {
            rate = 1;
        } else if (rate < 0) {
            rate = 0;
        }
        if (self.dragDelegate) {
            [self.dragDelegate playerSliderDragingProgress:rate];
        }

    }
}


@end
