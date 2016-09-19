//
//  FWNavigationController.m
//  FWAVPleyer
//
//  Created by 武建明 on 16/9/18.
//  Copyright © 2016年 Four_w. All rights reserved.
//

#import "FWNavigationController.h"
#import "FWMainViewController.h"
#import "PlayerViewController.h"

@interface FWNavigationController ()

@end

@implementation FWNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

// 哪些页面支持自动转屏
- (BOOL)shouldAutorotate{

    if ([self.topViewController isKindOfClass:[FWMainViewController class]]) {
        return NO;
    }else if ([self.topViewController isKindOfClass:[PlayerViewController class]]){
        PlayerViewController *vc = (PlayerViewController *)self.topViewController;
        return vc.playerView.shouldAutorotate;
    }
    return YES;
}
// viewcontroller支持哪些转屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{

    if ([self.topViewController isKindOfClass:[FWMainViewController class]]) { // MoviePlayerViewController这个页面支持转屏方向
        return UIInterfaceOrientationMaskPortrait;
    }else if ([self.topViewController isKindOfClass:[PlayerViewController class]]) { //

        PlayerViewController *vc = (PlayerViewController *)self.topViewController;
        if (vc.playerView.shouldAutorotate) {
            return UIInterfaceOrientationMaskAll;
        }else{
            return vc.playerView.interfaceOrientationMask;
        }
    }
    // 其他页面
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
