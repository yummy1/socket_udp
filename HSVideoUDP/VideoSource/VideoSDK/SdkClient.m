//
//  SdkClient.m
//  HdVideo
//
//  Created by 小宝左 on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "SdkClient.h"
#import "PingService.h"
#import <sys/ioctl.h>
#import <netinet/in.h>
#import <net/if.h>
#import <arpa/inet.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netdb.h>
#include <pthread.h>
#import "configService.h"
#import "VideoParser.h"
//#include <iostream>

@interface SdkClient(){
    NSMutableArray *callcollects;
    PingService *pingServices;
    PingStatus laststat;
    VideoParser *parser;
    pthread_t ConnectThread;
}
@end

static SdkClient* handle=nil;
@implementation SdkClient;

@synthesize fd;
@synthesize broadfd;
@synthesize Serverip;
@synthesize change;
@synthesize ipchange;
@synthesize connected;

+(SdkClient *)GetInstance
{
    if(handle == nil){
        printf("reinit data \n");
        handle = [[SdkClient alloc]init];
        handle->fd = -1;
        handle->broadfd = 0;
        handle->change = true;
        handle->callcollects = nil;
        handle->pingServices=nil;
        handle->connected = false;
        handle->ipchange = false;
        handle->laststat=PingStatusDidStart;
        [handle StartNetCheck];
        pthread_create(&handle->ConnectThread,    NULL, ReciveMedia,  NULL);
        /*
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //[self decode264];
            [ReciveMedia];
        });
         */
        
    }
    //printf("connect :: %d fd %d\n",handle->connected,handle->fd);
    return handle;
}

//-(void)RegisterCallBack:(callback) call{
//    if(nil == call)
//        return;
//
//    if(nil == handle->callcollects){
//        handle->callcollects=[[NSMutableArray alloc]init];
//    }
//    for(id fun in handle->callcollects){
//        if(fun == (void *)(call)){
//            return;
//        }
//    }
//    [handle->callcollects addObject:(__bridge id _Nonnull)((void *)call)];
//}
//
//-(void)RemoveCallBack:(callback) call{
//    if(nil == call)
//        return;
//
//    if(nil == handle->callcollects){
//        return;
//    }
//    for(id fun in handle->callcollects){
//        if(fun == (void *)(call)){
//            [handle->callcollects removeObject:(__bridge id _Nonnull)((void *)call)];
//        }
//    }
//}
-(void)StartNetCheck{
//    ConfigService *pServer =[ConfigService GetInstance];
//
////    [AlertShow ShowConnectMessage:"start  ping at %s\n",[pServer.ip UTF8String]];
//    NSLog(@"start  ping at %s\n",[pServer.ip UTF8String]);
//    handle->pingServices = [PingService startPingAddress:pServer.ip callbackHandler:^(PingItem *pingItem, NSArray *pingItems) {
//        if (pingItem.status == PingStatusDidTimeout) {
//            NSLog(@"timeout ... %s\n",[pServer.ip UTF8String]);
//
//            if(handle->laststat != pingItem.status){
//                handle->change = true;
//            }
//            handle->connected = false;
//            handle->laststat = pingItem.status;
//
//        }else if(pingItem.status == PingStatusDidReceivePacket){
//            if(handle->laststat != pingItem.status){
//                handle->change = true;
////                [AlertShow ShowConnectMessage:"disconnected ... \n"];
//                NSLog(@"disconnected ... \n");
//                handle->connected = false;
//            }
//            handle->laststat = pingItem.status;
//            if(!handle->connected){
//                printf("1.. start to connect file %s line %d\n",__FILE__,__LINE__);
////                [AlertShow ShowConnectMessage:"start to connect ... %s\n",[pServer.ip UTF8String]];
//                NSLog(@"start to connect ... %s\n",[pServer.ip UTF8String]);
//                handle->connected = [handle connetserver];
////                printf("2.. start to connect file %s line %d handle->connected::%d\n",__FILE__,__LINE__,handle->connected);
//            }
//            //printf("connect stat ..%d fd :: %d\n",handle->connected,handle->fd);
//        }
//        if(handle->change){
//            handle->change = false;
//
//            for(id fun in handle->callcollects){
//                void *call=(__bridge void *)(fun);
//                if(call)
//                    ((callback)(call))(pingItem.status == PingStatusDidReceivePacket);
//            }
//        }
//    }];
}

//-(void)stopCheck{
//    [handle->pingServices cancel];
//}

-(bool) connetserver{
    int nREUSEADDR=0;
    
    SdkClient *sdkClient=[SdkClient GetInstance];
#ifndef NO_CLOSE
    if(sdkClient->fd > 0){
        close(sdkClient->fd);
        sdkClient->fd = 0;
    }
#endif

#ifndef NET_RESET
    if(sdkClient->fd <= 0){
#endif
        sdkClient->fd=socket(AF_INET, SOCK_STREAM, 0);
    if(sdkClient->fd < 0){
//        AlertShow* pAlert=[AlertShow GetInstance];
//        [pAlert ShowAlert:@"提示" message:@"遇到了未知错误需要重启" quitlable:@"确定"];
        printf("err ..\n");
        return false;
    }
    
    setsockopt(sdkClient->fd,SOL_SOCKET,SO_REUSEADDR,(const char *)&nREUSEADDR,sizeof(int));
    //设置如Close时强置关闭
    struct linger m_sLinger = { 0 };
    m_sLinger.l_onoff = 1; // (在closesocket()调用,但是还有数据没发送完毕的时候容许逗留)
    m_sLinger.l_linger = 1; // (容许逗留的时间为1秒)
    setsockopt(sdkClient->fd,SOL_SOCKET,SO_LINGER,(const char *)&m_sLinger,sizeof(struct linger));
#ifndef NET_RESET
    }
#endif
    struct sockaddr_in m_serverAddr;
    ConfigService *pService=[ConfigService GetInstance];
    m_serverAddr.sin_addr.s_addr = inet_addr([pService.ip UTF8String]);
    m_serverAddr.sin_family = AF_INET;
    m_serverAddr.sin_port = htons(80);

    int m_connectFlag = connect(sdkClient->fd,&m_serverAddr, sizeof(m_serverAddr));
    NSLog(@"============connect ip %@ sdkClient->fd is %d m_connectFlag is %d\n",pService.ip,sdkClient->fd,m_connectFlag);
//    [AlertShow ShowConnectMessage:"ip %s fd is %d m_flag is %d\n",[pService.ip UTF8String],sdkClient->fd,m_connectFlag];
    if(errno == EISCONN){
        return true;
    }
    return m_connectFlag >= 0;
    
}

/*修改ip后，强制关闭
 */
//-(bool) disconnet{
//    //设置端口重用
//    SdkClient *sdkClient=[SdkClient GetInstance];
//    close(sdkClient->fd);
//    sdkClient->fd = -1;
//    return true;
//}
-(bool)ReciveData:(char *)buff size:(unsigned int)size{
    SdkClient *sdkClient=[SdkClient GetInstance];
    int index=0;
    ssize_t ret=0;
   
    while(index < size){
        ret=recv(sdkClient->fd,buff+index, size-index, MSG_DONTWAIT);
//        NSLog(@"bufferReciveData:--%s___%c",buff,size);
        if(ret == -1){
            if(errno == EAGAIN){
                usleep(10);
                //printf("no error ...\n");
                continue;
            }else{
                printf(" %s %d fale ...\n",__FILE__,__LINE__);
                sdkClient->connected = false;
                return false;}
        }else{
            if(ret > 0){index += ret;}
        }
    }
    NSLog(@"buffer:%2s",buff);
    return true;
}

//-(bool)SendData:(const char *)buff size:(unsigned int)size{
//    SdkClient *sdkClient=[SdkClient GetInstance];
//    int index=0;
//    ssize_t ret=0;
//    while(index < size){
//        ret=send(sdkClient->fd,buff+index, size-index, MSG_DONTWAIT);
//        printf("send data ... ret %zd\n",ret);
//        if(ret == -1){
//            if(errno == EAGAIN){
//                usleep(10);
//                continue;
//            }else{
//                printf(" %s %d fale ...\n",__FILE__,__LINE__);
//                sdkClient->connected = false;
//                return false;}
//        }else{
//            if(ret > 0){index += ret;}
//        }
//    }
//    return true;
//}



//-(bool)SkipHeader{
//    int rn = 0;
//    char c=0;
//    SdkClient *sdkClient=[SdkClient GetInstance];
//    while(1) { // skip \r\n\r\n
//        if(![sdkClient ReciveData:&c size:1])
//            return false;
//
//        if (c == '\r' || c == '\n') {++rn;}
//        else {rn = 0;}
//        if (rn == 4)break;
//    }
//    return true;
//}

-(bool)PutVideo:(unsigned int)size chn:(byte)chn type:(byte)type ts:(unsigned long long)ts{
    if(size <= 0)
        return true;
    
    char bf[size];
    SdkClient *sdkClient=[SdkClient GetInstance];
    if(![sdkClient ReciveData:bf size:size]){
        return false;
    }
    if(nil == parser)
        parser = [VideoParser alloc];
    [parser putVideoPacket:bf lenth:size];
    return true;
}

-(bool)PutVoice:(unsigned int)size chn:(byte)chn{
    if(size <= 0)
        return true;
    char bf[size];
    
    SdkClient *sdkClient=[SdkClient GetInstance];
    if(![sdkClient ReciveData:bf size:size]){
        return false;
    }

    return true;
}

//-(bool)StartMedia{
//    SdkClient *sdkClient=[SdkClient GetInstance];
//    printf("star media 。。。 \n");
//    const char * request = "GET /0.pte HTTP/1.1\r\n" "User-Agent: VLC/2.0.0\r\n" "\r\n";
//    unsigned int size = strlen(request);
//    return [sdkClient SendData:request size:size];
//}

void* ReciveMedia(void *pdata){
    SdkClient *sdkClient=[SdkClient GetInstance];
    printf("run recive ...\n");
//    while(1){
//
//        while(!sdkClient->connected || sdkClient->fd<0){
////            printf("sdkClient->connected is %d sdkClient->fd：%d \n",sdkClient->connected,sdkClient->fd);
//            usleep(500);
//        }
//        printf("connected ...\n");
//        if(![sdkClient StartMedia]){
//            printf("start meida bad...\n");
//            continue;
//        }
//        printf("start media ok...\n");
//        if(![sdkClient SkipHeader]){
//            printf("skip header ... bad \n");
//            continue;
//        }
//        printf("skip header ok ...\n");
        while(1){
            struct media_header h;
            if(![sdkClient ReciveData:(char *)&h size:sizeof(h)]){
                break;
            }
            if(h.protocol_version != 1 || h.size <= sizeof(h) || h.size >= 16*1024*1024)
                continue;
            bool reconnect = false;
            switch (h.pck_type) {
                case h264:
                    //printf("264 data ...");
                    if(![sdkClient PutVideo:h.size-sizeof(h) chn:h.chn type:h.pck_type ts:h.frame_ts]){
                        reconnect = true;
                    }
                break;
                case g711:
                    printf("voices data ...\n");
                    if(![sdkClient PutVoice:h.size - sizeof(h)chn:h.chn]){
                        reconnect = true;
                    }
                default:
                    printf("unknow data ...\n");
                break;
            }
            if(reconnect){
                break;
            }
            if(handle->ipchange){
                handle->ipchange = false;
                break;
            }
        }
//    }
    printf("finished bad...\n");
    return nil;
}
    
@end

