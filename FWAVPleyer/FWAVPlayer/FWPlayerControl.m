//
//  FWPlayerControl.m
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import "FWPlayerControl.h"

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionLeftOrRight,
    DirectionUpOrDown,
    DirectionNone
};

@interface FWPlayerControl ()

@property (assign, nonatomic) Direction direction;//滑动方向

@property (assign, nonatomic) CGPoint startPoint;

@property (assign, nonatomic) CGFloat startVB;//音量和亮度的开始点

@property (strong, nonatomic) MPVolumeView *volumeView;//控制音量的view
@property (strong, nonatomic) UISlider* volumeViewSlider;//控制音量
@property (assign, nonatomic) CGFloat currentSeconds;//滑动开始视频播放的进度

@end

@implementation FWPlayerControl{

    BOOL isBeiginSliderDrag;
}
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.playerView];
        [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}
- (UIView *)playerView{
    if (!_playerView) {
        _playerView = [[UIView alloc]init];
        _playerView.backgroundColor = [UIColor clearColor];
    }
    return _playerView;
}
- (FWAVPlayerManager *)playerManager{
    if (!_playerManager) {
        _playerManager = [[FWAVPlayerManager alloc]initOnView:self.playerView];
    }
    return _playerManager;
}
- (void)layoutSubviews{
    [super layoutSubviews];
}
//触摸开始
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.isDisableDrag) {
        return;
    }
    //获取触摸开始的坐标
    UITouch *touch = [touches anyObject];
    CGPoint currentP = [touch locationInView:self];
    [self touchesBeganWithPoint:currentP];
}

//触摸结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.isDisableDrag) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint currentP = [touch locationInView:self];
    [self touchesEndWithPoint:currentP];
}
//移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.isDisableDrag) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint currentP = [touch locationInView:self];
    [self touchesMoveWithPoint:currentP];
}

#pragma mark - 开始触摸
- (void)touchesBeganWithPoint:(CGPoint)point {
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.frame.size.width / 2.0) {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //音/量
        self.startVB = self.volumeViewSlider.value;
    }
    //方向置为无
    self.direction = DirectionNone;

    //记录触摸时,视频所在的位置
    self.currentSeconds =  CMTimeGetSeconds([self.playerManager currentDuration]);
    
    isBeiginSliderDrag = YES;

}
#pragma mark - 结束触摸
- (void)touchesEndWithPoint:(CGPoint)point {
    if (self.direction == DirectionLeftOrRight) {
        [self.playerManager endSliderDrag];
    }
}

#pragma mark - 拖动
- (void)touchesMoveWithPoint:(CGPoint)point {
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    //分析出用户滑动的方向
    if (self.direction == DirectionNone) {
        if (panPoint.x >= 30 || panPoint.x <= -30) {
            //进度
            self.direction = DirectionLeftOrRight;
        } else if (panPoint.y >= 30 || panPoint.y <= -30) {
            //音量和亮度
            self.direction = DirectionUpOrDown;
        }
    }

    if (self.direction == DirectionNone) {
        return;
    } else if (self.direction == DirectionUpOrDown) {
        //音量和亮度
        if (self.startPoint.x <= self.frame.size.width / 2.0) {
            //调节亮度
            if (panPoint.y < 0) {
                //增加亮度
                [[UIScreen mainScreen] setBrightness:self.startVB + (-panPoint.y / 30.0 / 10)];
            } else {
                //减少亮度
                [[UIScreen mainScreen] setBrightness:self.startVB - (panPoint.y / 30.0 / 10)];
            }

        } else {
            //音量
            if (panPoint.y < 0) {
                //增大音量
                [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-panPoint.y / 30 / 10) - self.volumeViewSlider.value >= 0.1) {
                    [self.volumeViewSlider setValue:0.1 animated:NO];
                    [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                }

            } else {
                //减少音量
                [self.volumeViewSlider setValue:self.startVB - (panPoint.y / 30.0 / 10) animated:YES];
            }
        }
    } else if (self.direction == DirectionLeftOrRight ) {

        if (isBeiginSliderDrag) {
            [self.playerManager beginSliderDrag];
        }
        isBeiginSliderDrag = NO;
        //进度
        CGFloat rate = panPoint.x/self.bounds.size.width;
        if (rate > 1) {
            rate = 1;
        } else if (rate < -1) {
            rate = -1;
        }

        CMTime itemDuration = [self.playerManager itemDuration];

        if (CMTIME_IS_INVALID(itemDuration)) {
            return;
        }

        double durationSeconds = CMTimeGetSeconds(itemDuration);

        if (isfinite(durationSeconds)){
            double time = self.currentSeconds+rate*durationSeconds;
            [self.playerManager sliderSeekToProgress:time/durationSeconds];
        }
    }
}
//开始设置进度
- (void)beginDragProgress{
    //记录触摸时,视频所在的位置
    [self.playerManager beginSliderDrag];
}
//设置进度百分比
- (void)dragingProgress:(CGFloat)progress{

    [self.playerManager sliderSeekToProgress:progress];
}
//设置完进度
- (void)endDragProgress{
    [self.playerManager endSliderDrag];
}
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}
- (void)setVideoUrl:(NSString *)videoUrl{

    _videoUrl = videoUrl;
    /* 判断视频来源,网络视频还是本地视频 */
    if ([self isValidUrl:_videoUrl]) {
        [self.playerManager setUrl:[NSURL URLWithString:_videoUrl]];
    }else{
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@.mp4",_videoUrl] ofType:nil];
        [self.playerManager setUrl:[NSURL fileURLWithPath:videoPath]];
    }
}
// 是否是网址
- (BOOL)isValidUrl:(NSString *)url
{
    NSString *regex =@"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [urlTest evaluateWithObject:url];
}

@end
