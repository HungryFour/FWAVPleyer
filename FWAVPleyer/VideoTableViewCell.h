//
//  VideoTableViewCell.h
//  FWAVPlayerDemo
//
//  Created by 武建明 on 16/8/24.
//  Copyright © 2016年 Four_w. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWPlayerView.h"

@class VideoTableViewCell;

@protocol VideoTableViewCellDelegate <NSObject>

- (void)cellDidClickPlay:(VideoTableViewCell *)cell;

@end

@interface VideoTableViewCell : UITableViewCell

@property (weak,nonatomic)id<VideoTableViewCellDelegate>delegate;

@property (strong,nonatomic)NSIndexPath *indexPath;

@property (strong,nonatomic)UIImageView *placeholderImageView;

@end
