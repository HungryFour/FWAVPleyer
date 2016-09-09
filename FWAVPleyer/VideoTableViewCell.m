//
//  VideoTableViewCell.m
//  FWAVPlayerDemo
//
//  Created by 武建明 on 16/8/24.
//  Copyright © 2016年 Four_w. All rights reserved.
//

#import "VideoTableViewCell.h"
#import <Masonry.h>
#import "FWAVPlayer.h"
#define kSMainWidth [UIScreen mainScreen].bounds.size.width
#define kSMainHeight [UIScreen mainScreen].bounds.size.height
#define kNavViewHeight 64
#define kVideoViewHeight kSMainWidth*(9.0/16.0)

@interface VideoTableViewCell ()

@property (strong, nonatomic) UIButton *playButton;


@end

@implementation VideoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        [self.contentView addSubview:self.placeholderImageView];
        [self.placeholderImageView addSubview:self.playButton];

        self.contentView.backgroundColor = [UIColor lightGrayColor];
        [self.placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.placeholderImageView);
            make.size.mas_equalTo(CGSizeMake(44, 44));
        }];

    }
    return self;
}
- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor clearColor];
        [_playButton setImage:FWAVPlayerImage(@"fw-player-play") forState:UIControlStateNormal];
        [_playButton setImage:FWAVPlayerImage(@"fw-player-pause") forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playClick) forControlEvents:UIControlEventTouchUpInside];
        _playButton.selected = NO;
    }
    return _playButton;
}
- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.backgroundColor = [UIColor clearColor];
        _placeholderImageView.userInteractionEnabled = YES;
        _placeholderImageView.image = [UIImage imageNamed:@"1"];
    }
    return _placeholderImageView;
}

- (void)playClick{

    NSLog(@"cell播放");
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidClickPlay:)]) {
        [self.delegate cellDidClickPlay:self];
    }
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
