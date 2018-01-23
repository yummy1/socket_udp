//
//  SdkClient.h
//  HdVideo
//
//  Created by 小宝左 on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef SdkClient_h
#define SdkClient_h
#include <string.h>
typedef int (*callback)(bool online);
typedef unsigned char byte;
enum pkg_type{
    h264 = 0,
    g711 = 110
};
struct media_header{
    unsigned int size; 		// (head + body)的大小
    byte protocol_version; 	// 固定为 1
    byte pck_type;  		// 数据类型
    byte chn;       		// 通道
    byte frame_type; 		// 帧的类型，0: I Frame, 1: P Frame //20150803
    unsigned long long frame_ts; 	// 时间戳
    unsigned long long frame_tmd; 	// 多余的8位
    //void * body;
} __attribute((packed));
@interface SdkClient : NSObject{

}
+(SdkClient *)GetInstance;

@property(nonatomic) volatile int  fd;
@property(nonatomic) volatile NSInteger  broadfd;
@property(nonatomic) volatile char       *Serverip;
@property(nonatomic) volatile NSInteger  change;
@property(nonatomic) volatile NSInteger  ipchange;
@property(nonatomic) volatile bool       connected;

-(void)RegisterCallBack:(callback) call;
-(void)RemoveCallBack:(callback) call;
-(bool)connetserver;
-(void)StartNetCheck;
-(void)stopCheck;
@end

#endif /* SdkClient_h */
