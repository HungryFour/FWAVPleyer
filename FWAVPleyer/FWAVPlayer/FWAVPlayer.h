//
//  FWAVPlayer.h
//  FWAVPleyer
//
//  Created by 武建明 on 16/9/7.
//  Copyright © 2016年 Four_w. All rights reserved.
//

#ifndef FWAVPlayer_h
#define FWAVPlayer_h

#define FWAVPlayerImage(file) [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"FWAVPlayerResources.bundle"] stringByAppendingPathComponent:file]]

//weak、strong对象
#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;


#endif /* FWAVPlayer_h */

