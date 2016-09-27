//
//  FWAVPlayerManager.m
//  播放器Demo
//
//  Created by 武建明 on 16/8/17.
//  Copyright © 2016年 WJM. All rights reserved.
//

#import "FWAVPlayerManager.h"

static void *kRateObservationContext = &kRateObservationContext;
static void *kStatusObservationContext = &kStatusObservationContext;
static void *kCurrentItemObservationContext = &kCurrentItemObservationContext;
static void *kTimeRangesObservationContext = &kTimeRangesObservationContext;

/* 本地是否还有可用缓存视频流监听 */
static void *kPlaybackBufferEmptyObservationContext = &kPlaybackBufferEmptyObservationContext;
static void *kPlaybackLikelyToKeepUpObservationContext = &kPlaybackLikelyToKeepUpObservationContext;

@interface FWAVPlayerManager ()

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, assign) BOOL isUserPause;             //用户手动暂停
@property (nonatomic, assign) BOOL isBufferEmptyPause;      //缓冲区为空导致暂停
@property (nonatomic, assign) BOOL hasBuffer;               //有缓冲
@property (nonatomic, assign) BOOL isEnterBackgound;        //后台运行
@property (nonatomic, assign) BOOL isSeekToZero;            //是否从头播放
//@property (nonatomic, assign) float recordPlayerRate;       //记录播放器状态,滑动之前记录,滑动之后复原
@property (nonatomic, assign) BOOL isClear;                 //loadValuesAsynchronouslyForKeys准备播放是一个异步的操作,如果在该动作未执行完毕时,播放结束,进程依旧,所以此处添加记录
@property (nonatomic, strong) id timeObserverForInterval;   //添加观察者,默认每隔一秒发送一次心跳
@property (nonatomic, strong) UIView *currentSuperView;     //当前的父视图,此对象是用来做父视图延迟加载的,当设置了URL后加载真正的父视图
@property (nonatomic, assign) CGFloat sliderProgress;       //滑动的百分比

@property (nonatomic, assign) BOOL isSliding;               //是否在滑动

@property (nonatomic, strong) AVAssetImageGenerator *generator;//取视频关键帧
@end

@implementation FWAVPlayerManager

- (instancetype)initOnView:(UIView *)superView{

    self = [super init];
    if (self) {
        _superView = superView;
    }
    return self;
}
#pragma mark - Property
- (AVAssetImageGenerator *)generator
{
    if (!_generator) {
        _generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    }
    return _generator;
}

- (void)setUrl:(NSURL *)url{
    if (_url != url) {

        [self removeObserver];

        self.isClear = NO;
        self.isUserPause = NO;
        self.isBufferEmptyPause = NO;
        self.isSeekToZero = NO;
        self.isSliding = NO;
        self.hasBuffer = NO;
        self.generator = nil;
        /* 切换视频时,将上个视频的页面删除,防止加载时的页面显示问题 */
        [self.avPlayerLayer removeFromSuperlayer];

        _url = [url copy];


        self.asset = [AVURLAsset URLAssetWithURL:url options:nil];
        /* 准备播放 */
        [self radioCurrentPlayStatus:FWAVPlayerPlayStateBuffering];

        // 使用断言去加载指定额键值
        [self.asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:
         ^{

             dispatch_async( dispatch_get_main_queue(),
                            ^{

                                NSError *error = nil;
                                AVKeyValueStatus tracksStatus = [self.asset statusOfValueForKey:@"playable" error:&error];

                                switch (tracksStatus) {
                                    case AVKeyValueStatusUnknown:
                                        NSLog(@"AVKeyValueStatusUnknown");

                                        break;

                                    case AVKeyValueStatusLoading:
                                        NSLog(@"AVKeyValueStatusLoading");


                                        break;

                                    case AVKeyValueStatusLoaded:
                                        NSLog(@"AVKeyValueStatusLoaded");

                                        /**
                                         *  因为这是异步操作，有可能执行到这儿的时候程序已经退出
                                         *  必须要确保当前播放进程没有退出
                                         */
                                        if (!self.isClear) {
                                            [self setPlayerLayerSuperView:self.superView];
                                            [self prepareToPlayAsset:self.asset];
                                        }
                                        break;
                                    case AVKeyValueStatusFailed:
                                        NSLog(@"AVKeyValueStatusFailed");
                                        [self playError:error];

                                        break;
                                    case AVKeyValueStatusCancelled:
                                        // Do whatever is appropriate for cancelation.
                                        NSLog(@"AVKeyValueStatusCancelled");
                                        break;
                                }
                            });
         }];
    }

}
// 播放前准备
- (void)prepareToPlayAsset:(AVURLAsset *)asset{

    /* 从successfully loaded AVAsset中创建一个新的AVPlayerItem instance. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];

    /* 如果没有player就去创建一个新的. */
    if (!self.player){
        _player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }

    /* 确保最新的PlayerItem就是 self.player.currentItem. */
    if (self.player.currentItem != self.playerItem){
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }

    [self addObserver];

}
- (void)setPlayerLayerSuperView:(UIView *)superView{

    if (self.currentSuperView != superView) {
        self.currentSuperView = superView;
        self.avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:_player];
        [self.avPlayerLayer setFrame:self.currentSuperView.bounds];
        if (!self.fillMode) {
            self.fillMode = FWPlayerVideoFillModeResizeAspectFill;
        }
    }
    if (self.avPlayerLayer.superlayer != self.currentSuperView.layer) {
        [self.currentSuperView.layer addSublayer:self.avPlayerLayer];
    }
}
#pragma mark - addObserver
- (void)addObserver{
    //缓冲区无缓存,不能播放
    [self.playerItem  addObserver:self
                       forKeyPath:@"playbackBufferEmpty"
                          options:NSKeyValueObservingOptionNew
                          context:kPlaybackBufferEmptyObservationContext];
    //缓冲区有缓存可以继续播放了
    [self.playerItem  addObserver:self
                       forKeyPath:@"playbackLikelyToKeepUp"
                          options:NSKeyValueObservingOptionNew
                          context:kPlaybackLikelyToKeepUpObservationContext];

    /* Observe the player 的 "status" key 去决定什么什么去播放. */
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kStatusObservationContext];
    /* 已经缓冲的值 */
    [self.playerItem addObserver:self
                      forKeyPath:@"loadedTimeRanges"
                         options:NSKeyValueObservingOptionNew
                         context:kTimeRangesObservationContext];

    /* 去监听当payer已经播放结束，可能要去做一些更新UI的操作*/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];

    /* 监听应用前后台切换 */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    /* 监听 AVPlayer "currentItem" 属性*/
    [self.player addObserver:self
                  forKeyPath:@"currentItem"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:kCurrentItemObservationContext];

    /* 监听 AVPlayer "rate" 属性 以便我们去更新播放进度控件. */
    [self.player addObserver:self
                  forKeyPath:@"rate"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:kRateObservationContext];

}
- (void)removeObserver{

    [self removeTimeObserverForInterval];

    [self.playerItem  removeObserver:self forKeyPath:@"status"];
    [self.playerItem  removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem  removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem  removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:self.playerItem];

    [self.player removeObserver:self forKeyPath:@"rate"];

    [self.player removeObserver:self forKeyPath:@"currentItem"];
}
- (void)addTimeObserverForInterval{

    __weak FWAVPlayerManager *weakSelf = self;
    self.timeObserverForInterval = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                         queue:NULL usingBlock:
                                    ^(CMTime time)
                                    {
                                        [weakSelf syncScrubber];
                                    }];

}
- (void)dealloc{
    NSLog(@"销毁");
    [self clear];
}
/* 取消先前注册的观察者 */
-(void)removeTimeObserverForInterval{
    if (self.timeObserverForInterval){
        [self.player removeTimeObserver:self.timeObserverForInterval];
        self.timeObserverForInterval = nil;
    }
}
- (void)appEnteredForeground{
    NSLog(@"开始前台运行");
    /**
     *  注意：appEnteredForeground 会在 AVPlayerItemStatusReadyToPlay（从后台回到前台会出发ReadyToPlay）
     *  之后被调用，顾设置 self.isEnterBackgound = NO 的操作放在了 AVPlayerItemStatusReadyToPlay 之中
     */
}
- (void)appEnteredBackground{
    NSLog(@"开始后台运行");
    self.isEnterBackgound = YES;
    [self.player pause];
}
/* 当前是否正在播放视频 */
- (BOOL)isPlaying{
//    return self.recordPlayerRate != 0.f || [self.player rate] != 0.f;
    return [self.player rate] != 0.f;
}
/* 播放结束的时候回调这个方法. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* 视频播放结束，再次播放需要从0位置开始播放 */
    self.isSeekToZero = YES;
    [self radioCurrentPlayStatus:FWAVPlayerPlayStateFinished];
}
/* 广播播放器状态 */
- (void)radioCurrentPlayStatus:(FWAVPlayerPlayState)playState{
    if (self.status) {
        self.status(playState);
    }
}
- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" 属性值观察. */
    if (context == kStatusObservationContext){

        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* 未知播放状态，尝试着去加载 */
            case AVPlayerItemStatusUnknown:
            {
                [self radioCurrentPlayStatus:FWAVPlayerPlayStateBuffering];
            }
                break;

            case AVPlayerItemStatusReadyToPlay:
            {
                /* 一旦 AVPlayerItem 准备好了去播放, i.e.
                 duration 值就可以去捕获到 （从后台回到前台也会触发 ReadyToPlay）*/
                if (!self.isEnterBackgound) {

                    if (self.player.rate == 0 && self.isUserPause) {
                        [self radioCurrentPlayStatus:FWAVPlayerPlayStatePause];
                    }else{
                        self.isUserPause = NO;
                        [self.player play];
                    }

                }else{
                    /**
                     *  如果是从后台回到前台，需要将 self.isEnterBackgound = NO
                     */
                    self.isEnterBackgound = NO;
                    if (self.isUserPause) {
                        [self radioCurrentPlayStatus:FWAVPlayerPlayStatePause];
                    }else{
                        [self.player play];
                    }

                }


            }
                break;

            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self playError:playerItem.error];
            }
                break;
        }
    }else if (context == kPlaybackBufferEmptyObservationContext){

        self.hasBuffer = NO;
        [self radioCurrentPlayStatus:FWAVPlayerPlayStateBuffering];

    }else if (context == kPlaybackLikelyToKeepUpObservationContext){

        self.hasBuffer = YES;
        // 有缓冲时,检测是否播放中,如果在播放中,则广播为正在播放
        if (self.playerItem.playbackLikelyToKeepUp && self.player.rate == 1){
            [self radioCurrentPlayStatus:FWAVPlayerPlayStatePlaying];
            
            if (!self.timeObserverForInterval){
                [self addTimeObserverForInterval];
            }
        }
    }
    /* AVPlayer "rate" 属性值观察. */
    else if (context == kRateObservationContext){

        /**
         *  暂停分两种：一个强制暂停（以就是点击了暂停按钮）
         *  另一种就是网络不好加载卡住了暂停。
         */
        if (self.player.rate == 0) {

            /* 缓存不够导致的暂停 或者初始化的时候也会走*/
            if (!self.isUserPause) {
                [self radioCurrentPlayStatus:FWAVPlayerPlayStateBuffering];
                self.isBufferEmptyPause = YES;
            }
            /* 正常情况下导致的暂停 */
            else{
                [self radioCurrentPlayStatus:FWAVPlayerPlayStatePause];
            }

        }
        /**
         *  播放都一样
         */
        if (self.player.rate > 0 && self.player.error == nil) {
            self.isUserPause = NO;
            self.isBufferEmptyPause = NO;
            [self radioCurrentPlayStatus:FWAVPlayerPlayStatePlaying];

            if (!self.timeObserverForInterval){
                [self addTimeObserverForInterval];
            }

        }

    }
    /* AVPlayer "currentItem" 属性值观察.
     当replaceCurrentItemWithPlayerItem方法回调发生的时候. */
    else if (context == kCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];

        /* 判断是否为空 */
        if (newPlayerItem == (id)[NSNull null]){
            [self playError:nil];
        }else
        {
            self.avPlayerLayer.player = self.player;
        }
    }
    /* 已经缓冲的视频 */
    else if (context == kTimeRangesObservationContext){

        NSArray* times = self.playerItem.loadedTimeRanges;
        /* 防止数组越界,此处做一判断 */
        if (times.count == 0) {
            return;
        }
        /* 取出数组中的第一个值 */
        NSValue* value = [times objectAtIndex:0];

        CMTimeRange range;
        [value getValue:&range];
        float start = CMTimeGetSeconds(range.start);
        float duration = CMTimeGetSeconds(range.duration);

        /* 得出缓存进度 */
        float videoAvailable = start + duration;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateVideoAvailable:videoAvailable];
        });
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}
/* 更新缓存 */
-(void)updateVideoAvailable:(float)videoAvailable {

    CMTime playerDuration = self.itemDuration;
    double progress = 0;
    /* 有可能播放器还没有准备好，playerDuration值为kCMTimeInvalid */
    if (playerDuration.value != 0) {
        double duration = CMTimeGetSeconds(playerDuration);
        progress = videoAvailable/duration;

        if (self.loadingPercentage) {
            self.loadingPercentage(progress);
        }
        /* 如果因为缓冲被暂停的，如果缓冲值已经够了，需要重新播放 */
        float minValue = 0;
        float maxValue = 1;
        double time = CMTimeGetSeconds([self.player currentTime]);
        double sliderProgress = (maxValue - minValue) * time / duration + minValue;

        /* 当前处于缓冲不够暂停状态时,并且不是用户手动暂停时,继续播放 */
        if ((progress - sliderProgress) > 0.01 &&
            self.player.rate == 0 &&
            self.isBufferEmptyPause && !self.isUserPause) {
            [self play];
        }
    }
}
-(void)playError:(NSError *)error{

    [self clear];
    [self radioCurrentPlayStatus:FWAVPlayerPlayStateFailed];
    NSLog(@"视频播放出错:%@",[error localizedFailureReason]);
}
#pragma mark - 公共方法
- (CMTime)currentDuration{
    if (self.isSliding) {

        /* 如果正在滑动时, currentDuration读取的是滑动条所在的位置时间*/

        CMTime itemDuration = [self itemDuration];
        double durationSeconds = CMTimeGetSeconds(itemDuration);

        if (CMTIME_IS_INVALID(itemDuration)) {
            return CMTimeMakeWithSeconds(durationSeconds, NSEC_PER_SEC);
        }else{
            if (isfinite(durationSeconds)){
                double time = _sliderProgress*durationSeconds;
                return CMTimeMakeWithSeconds(time, NSEC_PER_SEC);
            }else{
                return CMTimeMakeWithSeconds(durationSeconds, NSEC_PER_SEC);
            }
        }

    }else{
        return [self.player currentTime];
    }
}
- (void)currentImage:(void (^)(UIImage *))currentImageBlock{

    [self fpsImageInCMTime:[self.player currentTime] fpsImageBlock:^(UIImage *image) {
        currentImageBlock(image);
    }];
}
- (void)fpsImageInCMTime:(CMTime)time
           fpsImageBlock:(void (^)(UIImage *))fpsImageBlock{

    NSValue *timeValue = [NSValue valueWithCMTime:time];
    dispatch_queue_t queue = dispatch_queue_create("FWGeneratorQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"获取帧图片");
        [self.generator generateCGImagesAsynchronouslyForTimes:@[timeValue] completionHandler:^
         (CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error)
         {
             NSLog(@"获取帧图片结果");
             if (result == AVAssetImageGeneratorSucceeded){
                 NSLog(@"帧图片获取成功");
                 fpsImageBlock([UIImage imageWithCGImage:image]);
             }else{
                 NSLog(@"帧图片获取失败:%@",error);
                 fpsImageBlock(nil);
             }
         }];


    });
}

- (NSString *)currentDurationString{

    if (CMTIME_IS_INVALID(self.currentDuration)){
        return @"00:00:00";
    }else{
        double duration = CMTimeGetSeconds(self.currentDuration);
        if (isfinite(duration) && duration>0){
            double hoursElapsed = floor(duration / (60.0*60));
            double minutesElapsed = fmod(duration / 60, 60);
            double secondsElapsed = fmod(duration, 60.0);
            return [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", hoursElapsed, minutesElapsed, secondsElapsed];
        }else{
            return @"00:00:00";
        }
    }
    return @"00:00:00";
}
- (NSTimeInterval)currentDurationTimeInterval{

    if (CMTIME_IS_INVALID(self.currentDuration))
    {
        return 0;
    }else{
        double duration = CMTimeGetSeconds(self.currentDuration);
        if (isfinite(duration))
        {
            return fmod(duration, 60.0);

        }else{
            return 0;
        }
    }
    return 0;
}
- (CMTime)itemDuration{

    AVPlayerItem *playerItem = [_player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}
- (NSString *)itemDurationString{

    if (CMTIME_IS_INVALID(self.itemDuration))
    {
        return @"00:00:00";
    }else{
        double duration = CMTimeGetSeconds(self.itemDuration);

        if (isfinite(duration) && duration>0){
            double hoursElapsed = floor(duration / (60.0*60));
            double minutesElapsed = fmod(duration / 60, 60);
            double secondsElapsed = fmod(duration, 60.0);
            return [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", hoursElapsed, minutesElapsed, secondsElapsed];
        }else{
            return @"00:00:00";
        }
    }
    return @"00:00:00";
}
- (void)setFillMode:(FWPlayerVideoFillMode)fillMode{
    AVPlayerLayer *playerLayer = self.avPlayerLayer;
    // AVLayerVideoGravityResize,           // 非均匀模式。两个维度完全填充至整个视图区域
    // AVLayerVideoGravityResizeAspect,     // 等比例填充，直到一个维度到达区域边界
    // AVLayerVideoGravityResizeAspectFill  // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
    switch (fillMode) {
        case FWPlayerVideoFillModeResize:
            playerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
        case FWPlayerVideoFillModeResizeAspect:
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case FWPlayerVideoFillModeResizeAspectFill:
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;

        default:
            break;
    }
}
#pragma mark - 播放状态控制
- (void)play{
    /* 如果视频正处于播发的结束位置，我们需要调回到初始位置
     进行播放. */
    if (YES == self.isSeekToZero){
        self.isSeekToZero = NO;
        [self.player seekToTime:kCMTimeZero];
    }
    [_player play];
}
- (void)pause{
    self.isUserPause = YES;
    [_player pause];
}
- (void)resum{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}
- (void)clear{

    [self removeObserver];

    [self.player pause];
    self.isClear = YES;
    self.isUserPause = NO;
    self.isBufferEmptyPause = NO;
    self.isSeekToZero = NO;

    self.player = nil;
    self.playerItem = nil;
    self.avPlayerLayer = nil;
}
#pragma mark - 播放进度控制

// 开始拖动
- (void)beginSliderDrag{

    /* 滑动的时候是否暂停,如果需要可去掉注释 */
    
//    /* 记录开始拖动前的状态，拖动的时候必须要暂停 */
//    self.recordPlayerRate = [_player rate];
//
//    if (self.isBufferEmptyPause) {
//        /* 如果是当前网络问题，缓存不够导致的暂停 */
//        [_player setRate:0.f];
//    }else{
//        /* 正常播放的情况下 */
//        [self pause];
//    }

    self.isSliding = YES;
    [self removeTimeObserverForInterval];

    /* 通知开始拖动 */
    if (self.slideState) {
        self.slideState(FWAVPlayerPlaySlideStateBegin);
    }
}
// 拖动值发生改变
- (void)sliderSeekToProgress:(CGFloat)progress{

    if (progress > 1.00) {
        progress = 1.00;
    } else if (progress < 0) {
        progress = 0;
    }
    _sliderProgress = progress;

    /* 同步进度,但此时同步的是滑动进度 */
    [self syncScrubber];

    if (self.slideState) {
        self.slideState(FWAVPlayerPlaySlideStateSliding);
    }
    /* 滑动时,如果对外有获取帧图片的接口,并且数据来自于本地,则返回帧图片 */
    if (self.fpsImage && !self.isNetUrl) {
        [self fpsImageInCMTime:self.currentDuration fpsImageBlock:^(UIImage *image) {
            self.fpsImage(image);
        }];
    }
}
// 结束拖动
- (void)endSliderDrag{

    NSLog(@"结束拖动");
    self.isSliding = NO;

    /* 滑动结束后跳转到相应的时刻 */
    CMTime itemDuration = [self itemDuration];

    if (self.slideState) {
        self.slideState(FWAVPlayerPlaySlideStateEnd);
    }
    if (CMTIME_IS_INVALID(itemDuration)) {
        return;
    }
    double durationSeconds = CMTimeGetSeconds(itemDuration);

    if (isfinite(durationSeconds)){
        double time = _sliderProgress*durationSeconds;
        [self sliderSeekToTime:time];
    }

    /* 如果拖动到结束.则发送结束通知 */
    if (_sliderProgress == 1) {
        /* 视频播放结束，再次播放需要从0位置开始播放 */
        self.isSeekToZero = YES;
        [self radioCurrentPlayStatus:FWAVPlayerPlayStateFinished];
    }

}
// 跳转到相应时刻
- (void)sliderSeekToTime:(CGFloat)time{
    [_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {

        if (!self.timeObserverForInterval){
            [self addTimeObserverForInterval];
        }

    }];
}
// 同步进度
- (void)syncScrubber{

    CMTime playerDuration = self.itemDuration;
    if (CMTIME_IS_INVALID(playerDuration)){

        if (self.progress) {
            self.progress(0.0f);
        }

    }else{
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)){

            double currentTime = CMTimeGetSeconds(self.currentDuration);
            double itemTime = CMTimeGetSeconds(self.itemDuration);
            
            if (self.progress) {
                self.progress(currentTime/itemTime);
            }
            
        }else{

            if (self.progress) {
                self.progress(0.0f);
            }
        }
        
    }
    
}


@end
