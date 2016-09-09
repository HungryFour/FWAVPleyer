//
//  FWPlayerView.m
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import "FWPlayerView.h"
#import "FWPlayerSlider.h"
#import "FWAVPlayer.h"

static const CGFloat kUIShowTimeInterval = 0.3;//UI渐变时间
static const CGFloat kUIAutoHideTimeInterval = 3.0;//UI显示时间
static const CGFloat kBottomBarFullScreenHeight = 44.0;//全屏状态底部操作栏高度
static const CGFloat kBottomBarShrinkScreenHeight = 30.0;//非全屏状态底部操作栏高度

@interface FWPlayerView ()<FWPlayerSliderDragDelegate>

@property (strong,nonatomic)UIView *playUI;//所有的控件都帖在此View

@property (strong,nonatomic)UIView *bottomBar;//底部控件都帖在此View

@property (strong,nonatomic)UIButton *playButton;//播放暂停

@property (strong,nonatomic)UIButton *repeatButton;//播放暂停

@property (nonatomic, strong) UILabel *currentTimeLabel;//当前时间

@property (nonatomic, strong) UILabel *totalTimeLabel;//总时间

@property (nonatomic, strong) FWPlayerSlider *progressSlider;//进度条

@property (strong,nonatomic)UIButton *fullScreenButton;//全屏按钮

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;//小菊花

@property (nonatomic, assign) BOOL isShowUI;//是否显示UI

@property (nonatomic, assign)UIView *originalSuperView;//原始SuperView,全屏时所用

@property (nonatomic, assign)CGRect originalFrame;//原始Frame,全屏时所用

@property (nonatomic, assign)NSInteger originalIndex;//原始index,在父视图中属于第几层,全屏时所用

@property (nonatomic, assign)kDeviceOrientation deviceOrientation;//屏幕旋转方向

@property (nonatomic, assign)BOOL hasDeviceOrientationObserver;//检测屏幕方向的观察者是否存在

@end

@implementation FWPlayerView

- (instancetype)initWithFrame:(CGRect)frame{

    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (instancetype)init{

    self = [super init];
    if (self) {
        [self setup];
    }
    return self;

}
- (void)dealloc{
    [self removeObserver];
}

- (void)setup{

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [self addGestureRecognizer:tapGesture];
    self.translatesAutoresizingMaskIntoConstraints = NO;

    self.isShowUI = YES;
    self.isFullscreenMode = NO;
    self.isMini = NO;
    self.isClearFinished = NO;
    self.state = FWAVPlayerPlayStateBuffering;
    self.isDisableDrag = YES;
    self.hasDeviceOrientationObserver = NO;
    self.rotationLock = YES;
    self.deviceOrientation = kDeviceOrientationPortrait;

    [self addViews];
    [self setConstraints];

//    [self addObserver];
    [self acceptPlayerManagerBlock];

}
- (void)addObserver{


}
- (void)removeObserver{

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    UIDevice *device = [UIDevice currentDevice];
    [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:device];
    self.hasDeviceOrientationObserver = NO;

}
/* 获取来自playerManager的Block */
- (void)acceptPlayerManagerBlock{

    @WeakObj(self);

    /* 播放进度 */
    self.playerManager.progress = ^(CGFloat progress){
        @StrongObj(self);
        self.currentTimeLabel.text = self.playerManager.currentDurationString;
        self.totalTimeLabel.text = self.playerManager.itemDurationString;
        self.progressSlider.topProgress = progress;
        if (progress < 0.2) {
            NSLog(@"窝草");
        }
    };

    /* 缓冲进度 */
    self.playerManager.loadingPercentage = ^(CGFloat loadingPercentage){
        @StrongObj(self);
        self.progressSlider.midProgress = loadingPercentage;
    };

    /* 滑动状态 */
    self.playerManager.slideState = ^(FWAVPlayerPlaySlideState slideState){
        @StrongObj(self);

        switch (slideState) {
            case FWAVPlayerPlaySlideStateBegin:
                self.progressSlider.fpsImageView.hidden = YES;
                break;
                
            case FWAVPlayerPlaySlideStateSliding:
                self.progressSlider.fpsImageView.hidden = NO;
                [self autoFadeOutUI];
                break;

            case FWAVPlayerPlaySlideStateEnd:
                self.progressSlider.fpsImageView.hidden = YES;
                self.playUI.alpha = 1.0;
                self.isShowUI = YES;
                break;

            default:
                break;
        }

    };


    /* 帧图片 */
    self.playerManager.fpsImage = ^(UIImage *image){
        @StrongObj(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressSlider.fpsImageView.image = image;

        });
    };

    /* 缓冲状态 */
    self.playerManager.status = ^(FWAVPlayerPlayState status){
        @StrongObj(self);

        if (self.stateDelegate && [self.stateDelegate respondsToSelector:@selector(playerView:state:)]) {
            [self.stateDelegate playerView:self state:status];
        }

        self.state = status;

        /* 准备出错 */
        if (status == FWAVPlayerPlayStateFailed) {
            [self resetUI];
        }
        /* 播放结束后 */
        if (status == FWAVPlayerPlayStateFinished) {
            self.repeatButton.hidden = NO;
            self.playButton.hidden = YES;

            /* 如果设置了播放完成后清除,则删除self */
            if (self.isClearFinished) {
                [self.playerManager clear];
                [self removeFromSuperview];
                return ;
            }
            /* 播放结束后结束全屏状态 */
            if (self.isFullscreenMode) {
                [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationPortrait  animated:NO];
                [self shrinkScreen];
            }

        }else{
            self.repeatButton.hidden = YES;
            self.playButton.hidden = NO;
        }
        /* 加载时 */
        if (status == FWAVPlayerPlayStateBuffering) {
            [self.indicatorView startAnimating];
            self.playButton.hidden = YES;
        }else{
            [self.indicatorView stopAnimating];
        }
        /* 播放时 */
        if (status == FWAVPlayerPlayStatePlaying) {
            self.playButton.selected = YES;
        }else{
            self.playButton.selected = NO;
            [self animateShow];
        }
        /* 准备暂停 */
        if (status == FWAVPlayerPlayStatePause) {
            [self resetUI];
        }
    };
}
- (void)addViews{

    [self addSubview:self.placeholderImageView];
    [self addSubview:self.playUI];
    [self sendSubviewToBack:self.placeholderImageView];

    [self.playUI addSubview:self.playButton];
    [self.playUI addSubview:self.repeatButton];
    [self.playUI addSubview:self.bottomBar];
    [self.playUI addSubview:self.indicatorView];

    [self.bottomBar addSubview:self.currentTimeLabel];
    [self.bottomBar addSubview:self.progressSlider];
    [self.bottomBar addSubview:self.totalTimeLabel];
    [self.bottomBar addSubview:self.fullScreenButton];

}
- (void)setConstraints{

    [self.playUI mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.playUI);
    }];


    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.playUI);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];
    [self.repeatButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.playUI);
        make.size.mas_equalTo(CGSizeMake(40, 60));
    }];

    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.playUI.mas_bottom).offset(0);
        make.left.equalTo(self.playUI.mas_left).offset(0);
        make.right.equalTo(self.playUI.mas_right).offset(0);
        make.height.mas_equalTo(kBottomBarShrinkScreenHeight);
    }];

    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomBar.mas_bottom).offset(0);
        make.left.equalTo(self.bottomBar.mas_left).offset(10);
        make.width.greaterThanOrEqualTo(@45);
        make.height.equalTo(self.bottomBar.mas_height);
    }];

    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomBar.mas_bottom).offset(0);
        make.right.equalTo(self.fullScreenButton.mas_left).offset(0);
        make.width.greaterThanOrEqualTo(@45);
        make.height.equalTo(self.bottomBar.mas_height);
    }];

    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomBar.mas_right).offset(0);
        make.width.equalTo(self.bottomBar.mas_height);
        make.centerY.equalTo(self.totalTimeLabel.mas_centerY);
        make.height.equalTo(self.bottomBar.mas_height);
    }];

    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBar.mas_centerY);
        make.left.equalTo(self.currentTimeLabel.mas_right).offset(10);
        make.right.equalTo(self.totalTimeLabel.mas_left).offset(-10);
        make.height.equalTo(self.bottomBar.mas_height);
    }];
}
#pragma mark - Property
- (UIView *)playUI{
    if (!_playUI) {
        _playUI = [[UIView alloc]init];
        _playUI.backgroundColor = [UIColor clearColor];
        _playUI.clipsToBounds = YES;
        _playUI.tag = 100;
    }
    return _playUI;
}
- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.backgroundColor = [UIColor redColor];
        _placeholderImageView.userInteractionEnabled = YES;
    }
    return _placeholderImageView;
}
- (UIView *)bottomBar{
    if (!_bottomBar) {
        _bottomBar = [[UIView alloc]init];
        _bottomBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    }
    return _bottomBar;
}
- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor clearColor];
        [_playButton setImage:FWAVPlayerImage(@"fw-player-play") forState:UIControlStateNormal];
        [_playButton setImage:FWAVPlayerImage(@"fw-player-pause") forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _playButton.selected = NO;
    }
    return _playButton;
}
- (UIButton *)repeatButton
{
    if (!_repeatButton) {
        _repeatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _repeatButton.backgroundColor = [UIColor clearColor];
        [_repeatButton setImage:FWAVPlayerImage(@"fw_repeat_video") forState:UIControlStateNormal];
        [_repeatButton setImage:FWAVPlayerImage(@"fw_repeat_video") forState:UIControlStateSelected];
        [_repeatButton addTarget:self action:@selector(repeatButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _repeatButton.selected = NO;
        _repeatButton.hidden = YES;
    }
    return _repeatButton;
}
- (UIButton *)fullScreenButton
{
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fullScreenButton.backgroundColor = [UIColor clearColor];
        [_fullScreenButton setImage:FWAVPlayerImage(@"fw-player-fullscreen") forState:UIControlStateNormal];
        [_fullScreenButton setImage:FWAVPlayerImage(@"fw-player-shrinkscreen") forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(fullScreenClick:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _fullScreenButton;
}

- (FWPlayerSlider *)progressSlider
{
    if (!_progressSlider) {
        _progressSlider = [[FWPlayerSlider alloc] init];
        _progressSlider.dragDelegate = self;
    }
    return _progressSlider;
}
- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [UILabel new];
        _totalTimeLabel.backgroundColor = [UIColor clearColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:10];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        _totalTimeLabel.text = @"00:00:00";

    }
    return _totalTimeLabel;
}
- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [UILabel new];
        _currentTimeLabel.backgroundColor = [UIColor clearColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:10];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.textAlignment = NSTextAlignmentRight;
        _currentTimeLabel.text = @"00:00:00";
    }
    return _currentTimeLabel;
}
- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_indicatorView stopAnimating];
    }
    return _indicatorView;
}
#pragma mark - Setting
/* 设置方向锁 */
- (void)setRotationLock:(BOOL)rotationLock{

    _rotationLock = rotationLock;

    /* 如果锁为NO 并且观察者不存在 则添加 */
    if (!_rotationLock && !self.hasDeviceOrientationObserver) {
        UIDevice *device = [UIDevice currentDevice];
        [device beginGeneratingDeviceOrientationNotifications];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
        self.hasDeviceOrientationObserver = YES;

    }else{
        /* 说明观察者存在 */
        if (self.hasDeviceOrientationObserver) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            UIDevice *device = [UIDevice currentDevice];
            [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:device];
        }
        self.hasDeviceOrientationObserver = NO;
    }
}
/* 设置屏幕方向 */
- (void)setDeviceOrientation:(kDeviceOrientation)deviceOrientation{

    if (_deviceOrientation == deviceOrientation) {
        return;
    }
    _deviceOrientation = deviceOrientation;

    switch (self.deviceOrientation) {
        case kDeviceOrientationPortrait:

            [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationPortrait  animated:NO];
            [self shrinkScreen];

            break;
        case kDeviceOrientationPortraitUpsideDown:
            /* 不做处理 */
            break;
        case kDeviceOrientationLandscapeLeft:

            [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationLandscapeRight  animated:NO];
            [self fullScreenWith:CGAffineTransformMakeRotation(M_PI_2)];

            break;
        case kDeviceOrientationLandscapeRight:

            [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationLandscapeLeft  animated:NO];
            [self fullScreenWith:CGAffineTransformMakeRotation(-M_PI_2)];

            break;
        default:
            break;
    }
}
#pragma mark - FWPlayerSliderDragDelegate
- (void)playerSliderBeginDragProgress{
    [self beginDragProgress];
}
- (void)playerSliderEndDragProgress{
    [self endDragProgress];
}
- (void)playerSliderDragingProgress:(CGFloat)progress{
    [self dragingProgress:progress];
}
#pragma mark - Action
- (void)playButtonClick{

    if (self.playerManager.isPlaying) {
        [self.playerManager pause];
    }else{
        [self.playerManager play];
    }
}
/* 重播 */
- (void)repeatButtonClick{
    [self.playerManager resum];
}
- (void)fullScreenClick:(UIButton *)button{
    if (button.selected) {
        [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationPortrait  animated:NO];
        [self shrinkScreen];
        button.selected = NO;
    }else{

        if (self.deviceOrientation == kDeviceOrientationLandscapeRight) {

            [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationLandscapeLeft  animated:NO];
            [self fullScreenWith:CGAffineTransformMakeRotation(-M_PI_2)];
        }else{

            [[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationLandscapeRight  animated:NO];
            [self fullScreenWith:CGAffineTransformMakeRotation(M_PI_2)];

        }
        button.selected = YES;
    }
}
/* 全屏 */
- (void)fullScreenWith:(CGAffineTransform)transform
{
    /* 全屏的时候加入手势控制 */
    self.isDisableDrag = NO;

    if (!self.isFullscreenMode) {

        /* 暂存原View,从原View上删除,添加到keyWindow中 */
        self.originalSuperView = self.superview;
        self.originalFrame = self.frame;
        self.originalIndex = [[self.superview subviews] indexOfObject:self];

        [self removeFromSuperview];
        [[UIApplication sharedApplication].keyWindow addSubview:self];

        CGFloat height = [[UIScreen mainScreen] bounds].size.width;
        CGFloat width = [[UIScreen mainScreen] bounds].size.height;

        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo((width - height) / 2);
            make.top.mas_equalTo((height - width) / 2);
            make.width.mas_equalTo(height);
            make.height.mas_equalTo(width);
        }];

        [self.bottomBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.playUI.mas_bottom).offset(0);
            make.left.equalTo(self.playUI.mas_left).offset(0);
            make.right.equalTo(self.playUI.mas_right).offset(0);
            make.height.mas_equalTo(kBottomBarFullScreenHeight);
        }];

        // 告诉self.view约束需要更新
        [self setNeedsUpdateConstraints];
        // 调用此方法告诉self.view检测是否需要更新约束，若需要则更新，下面添加动画效果才起作用
        [self updateConstraintsIfNeeded];

    }

    [UIView animateWithDuration:0.3 animations:^{
        [self setTransform:transform];
        [self layoutIfNeeded];
        NSLog(@"fullScreen");

    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;

    }];
}
/* 取消全屏 */
- (void)shrinkScreen
{
    if (!self.isFullscreenMode) {
        return;
    }
    /* 非全屏的时候禁止手势控制 */
    self.isDisableDrag = YES;

    /* 从window上删除,添加到原来的View中 */
    [self removeFromSuperview];
    [self.originalSuperView addSubview:self];
    /* 解决View的遮罩问题 */
    [self.originalSuperView insertSubview:self atIndex:self.originalIndex];

    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.originalFrame.origin.x);
        make.top.mas_equalTo(self.originalFrame.origin.y);
        make.width.mas_equalTo(self.originalFrame.size.width);
        make.height.mas_equalTo(self.originalFrame.size.height);
    }];

    [self.bottomBar mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.playUI.mas_bottom).offset(0);
        make.left.equalTo(self.playUI.mas_left).offset(0);
        make.right.equalTo(self.playUI.mas_right).offset(0);
        make.height.mas_equalTo(kBottomBarShrinkScreenHeight);
    }];

    // 告诉self.view约束需要更新
    [self setNeedsUpdateConstraints];
    // 调用此方法告诉self.view检测是否需要更新约束，若需要则更新，下面添加动画效果才起作用
    [self updateConstraintsIfNeeded];

    [UIView animateWithDuration:0.3 animations:^{

        [self setTransform:CGAffineTransformIdentity];
        [self layoutIfNeeded];
        NSLog(@"shrinkScreen");


    } completion:^(BOOL finished) {

        self.isFullscreenMode = NO;
    }];
}
/* 更新约束 */
- (void)updatePlayerViewConstraints{
    // 约束需要更新
    [self setNeedsUpdateConstraints];
    // 调用此方法告诉self检测是否需要更新约束，若需要则更新，下面添加动画效果才起作用
    [self layoutIfNeeded];
}
- (void)layoutSubviews{
    [super layoutSubviews];
    NSLog(@"layoutSubviews");
    [self.playerManager.avPlayerLayer setFrame:self.playerView.bounds];
}
/* 隐藏UI */
- (void)animateHide
{
    if (!self.isShowUI) {
        return;
    }
    [UIView animateWithDuration:kUIShowTimeInterval animations:^{
        self.playUI.alpha = 0.0;

    } completion:^(BOOL finished) {
        self.isShowUI = NO;
        if (self.isFullscreenMode) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }

    }];
}
/* 展示UI */
- (void)animateShow
{
    if (self.isShowUI) {
        return;
    }
    [UIView animateWithDuration:kUIShowTimeInterval animations:^{
        self.playUI.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (self.isFullscreenMode) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
        self.isShowUI = YES;
        [self autoFadeOutUI];
    }];
}
/* 自动展示UI */
- (void)autoFadeOutUI
{
    if (!self.isShowUI) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
    [self performSelector:@selector(animateHide) withObject:nil afterDelay:kUIAutoHideTimeInterval];
}
/* 取消展示UI */
- (void)cancelautoFadeOutUI
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
}
- (void)onTap:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isShowUI) {
            [self animateHide];
        } else {
            [self animateShow];
        }
    }
}
/* 重置UI */
- (void)resetUI{

    self.currentTimeLabel.text = @"00:00:00";
    self.totalTimeLabel.text = @"00:00:00";
    self.progressSlider.topProgress = 0;
    self.progressSlider.midProgress = 0;
    
}
/* 屏幕方向改变 */
- (void)orientationChanged:(NSNotification *)note  {

    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    switch (o) {
        case UIDeviceOrientationPortrait:
            NSLog(@"UIDeviceOrientationPortrait:Home键在底部");
            self.deviceOrientation = kDeviceOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:            NSLog(@"UIDeviceOrientationPortraitUpsideDown:Home键在顶部");
            self.deviceOrientation = kDeviceOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:            NSLog(@"UIDeviceOrientationLandscapeLeft:Home键在右边");
            self.deviceOrientation = kDeviceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.deviceOrientation = kDeviceOrientationLandscapeRight;
            NSLog(@"UIDeviceOrientationLandscapeRight:Home键在左边");
            break;
        default:
            break;
    }
}
@end
