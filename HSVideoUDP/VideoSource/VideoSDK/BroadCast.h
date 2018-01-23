//
//  BoardCast.h
//  HdVideo
//
//  Created by 小宝左 on 16/9/21.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef BoardCast_h
#define BoardCast_h
#import <sys/ioctl.h>
#import <netinet/in.h>
#import <net/if.h>
#import <arpa/inet.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netdb.h>
#include <pthread.h>
@interface BroadCastServer:NSObject{

}

+(BroadCastServer *)GetInstance;
@end

#endif /* BoardCast_h */
