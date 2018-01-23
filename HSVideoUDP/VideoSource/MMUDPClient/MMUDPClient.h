//
//  MMUDPClient.h
//  HSVideoUDP
//
//  Created by MM on 2017/12/22.
//  Copyright © 2017年 MM. All rights reserved.
//

#import <Foundation/Foundation.h>
//@protocol MMUDPClientDelegate <NSObject>
//-(void)recvVideoData:(unsigned char*)videoData andDataLength:(int)length; // 收到视频数据 进行解码
//@end
@interface MMUDPClient : NSObject
//@property (nonatomic, assign) id<MMUDPClientDelegate> delegate;

-(int)startUDPConnection; // 从沙盒中取出的数据
-(void)stopUDPConnect;
@end
