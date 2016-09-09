//
//  ViewController.m
//  FWAVPlayerDemo
//
//  Created by 武建明 on 16/8/18.
//  Copyright © 2016年 Four_w. All rights reserved.
//

#import "ViewController.h"
#import "FWPlayerView.h"
#import "VideoTableViewCell.h"
#import "PlayerViewController.h"
#import "FWVideoModel.h"
#import <MJExtension.h>
#import <UIImageView+WebCache.h>

#define kSMainWidth [UIScreen mainScreen].bounds.size.width
#define kSMainHeight [UIScreen mainScreen].bounds.size.height
#define kNavViewHeight 64
#define kVideoViewHeight kSMainWidth*(9.0/16.0)
#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,VideoTableViewCellDelegate,FWPlayerViewStateDelegate>

@property (strong, nonatomic)UITableView *tableView;

@property (strong, nonatomic)NSIndexPath *playingIndexPath;

@property (strong,nonatomic)FWPlayerView *playerView;
@property (strong,nonatomic)NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"FWVideoList" ofType:@"plist"];
    self.dataArray = [FWVideoModel mj_objectArrayWithKeyValuesArray:[[NSArray alloc] initWithContentsOfFile:plistPath]];

    [self.view addSubview:self.tableView];

}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.playerView.playerManager clear];
    [self.playerView removeFromSuperview];
    self.playerView = nil;
}
#pragma mark - Property
- (UITableView *)tableView{

    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = kVideoViewHeight;
    }
    return _tableView;

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
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *cellID = @"VideoTableViewCell";
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[VideoTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    FWVideoModel *model = [self.dataArray objectAtIndex:indexPath.row];
    [cell.placeholderImageView sd_setImageWithURL:[NSURL URLWithString:model.img]];
    cell.indexPath = indexPath;
    cell.delegate = self;

    return cell;
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PlayerViewController *pvc = [[PlayerViewController alloc]init];
    pvc.videoModel = [self.dataArray objectAtIndex:indexPath.row];
    [self presentViewController:pvc animated:YES completion:^{

    }];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self setPlayerViewSuperView];

}
#pragma mark - VideoTableViewCellDelegate
- (void)cellDidClickPlay:(VideoTableViewCell *)cell{

    [self removePlayerView];

    if (self.playingIndexPath != cell.indexPath) {
        self.playingIndexPath = cell.indexPath;
    }
    FWVideoModel *model = [self.dataArray objectAtIndex:cell.indexPath.row];

    self.playerView.videoUrl = model.video;

    [self.playerView.placeholderImageView sd_setImageWithURL:[NSURL URLWithString:model.img]];
    [self setPlayerViewSuperView];
}
- (void)setPlayerViewSuperView{

    /* 如果播放器不在播放和加载中,则删除 */
    if (self.playerView.state == FWAVPlayerPlayStateFailed){
        [self removePlayerView];
        return;
    }
    /* 如果播放器是全屏状态,则啥也不干 */
    if (self.playerView.isFullscreenMode) {
        return;
    }

    VideoTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingIndexPath];
    NSArray *visableCells = self.tableView.visibleCells;

    if ([visableCells containsObject:cell]) {
        NSLog(@"应该在cell上");
        if (![cell.contentView.subviews containsObject:self.playerView]) {

            NSLog(@"添加到cell.contentView");
            [cell.contentView addSubview:self.playerView];

            [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(cell.contentView);
            }];
            /* 告诉self.playerView约束需要更新 */
            [self.playerView updatePlayerViewConstraints];
            [self.tableView reloadData];

        }

    }else {
        NSLog(@"在底部");
        /* 如果已经添加到view中,则不必添加 */
        if (![self.view.subviews containsObject:self.playerView]&&self.playerView.superview) {

            NSLog(@"添加到self.view");

            [self.view addSubview:self.playerView];
            [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(200);
                make.height.mas_equalTo(120);
                make.bottom.equalTo(self.view.mas_bottom).offset(-5);
                make.right.equalTo(self.view.mas_right).offset(-5);
            }];
            /* 告诉self.playerView约束需要更新 */
            [self.playerView updatePlayerViewConstraints];
            [self.tableView reloadData];
        }
    }
}
- (void)removePlayerView{
    if (self.playerView.superview) {
        [self.playerView removeFromSuperview];
    }
}
#pragma mark - FWPlayerViewStateDelegate
- (void)playerView:(FWPlayerView *)playerView state:(FWAVPlayerPlayState)state{

    switch (state) {

        case FWAVPlayerPlayStatePlaying:
            NSLog(@"FWAVPlayerPlayStatePlaying");
            [self setPlayerViewSuperView];
            break;
        case FWAVPlayerPlayStatePause:
            NSLog(@"FWAVPlayerPlayStatePause");
            [self setPlayerViewSuperView];
            break;
        case FWAVPlayerPlayStateFinished:
            NSLog(@"FWAVPlayerPlayStateFinished");
//            [self removePlayerView];
            break;
        case FWAVPlayerPlayStateBuffering:
            NSLog(@"FWAVPlayerPlayStateBuffering");
            [self setPlayerViewSuperView];
            break;
        case FWAVPlayerPlayStateFailed:
            NSLog(@"FWAVPlayerPlayStateFailed");
            [self removePlayerView];

            break;

        default:
            break;
    }
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
