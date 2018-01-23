//
//  MMUDPClient.m
//  HSVideoUDP
//
//  Created by MM on 2017/12/22.
//  Copyright © 2017年 MM. All rights reserved.
//

#import "MMUDPClient.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import "VideoParser.h"

typedef struct msgHeader
{
    int       headerIdentifying;  // 协议头，以8888开头
    int       contentLength;      // 正文长度-> 包后面跟的数据的长度
    
}HJ_MsgHeader;



@interface MMUDPClient()
{
    int                 m_sockfd;
    struct sockaddr_in  m_serveraddr;   // 服务器地址
    
    VideoParser *parser;
}

#define SERVER_PORT 1234  // 发送端口   服务器开放给我们的端口号
#define fuwuIp          @"192.168.42.30"
@property (nonatomic, assign) BOOL recvSignal;
@end
@implementation MMUDPClient
- (instancetype)init
{
    self = [super init];
    if (self) {
        m_sockfd = -1;
        self.recvSignal = false;
    }
    return self;
}
-(int)startUDPConnection
{
//    self.returnDataBlock = block;
    self.recvSignal = true;
    
    // -------------- 1. socket -------------
    m_sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    //    NSLog(@"startUDPSearch ======= , %d", m_sockfd);
    if (m_sockfd < 0) {
        perror("socket: error\n");
        return 0;
    }
    
    m_serveraddr.sin_family = AF_INET;
    m_serveraddr.sin_addr.s_addr = htonl(INADDR_ANY); // 255.255.255.255
    m_serveraddr.sin_port = htons(1234);  // htons 将整型变量从主机字节顺序转变成网络字节顺序，即小端转大端
    
    // ---- 2-1. 向服务端地址发送数据广播：---limited broadcast,广播地址是255.255.255.255, 需要做一个SetSockopt():
    int broadCast = 1;
    if (setsockopt(m_sockfd, SOL_SOCKET, SO_REUSEADDR, &broadCast, sizeof(broadCast)) < 0) {
        perror("setsockopt");
        return 0;
    }
    
    if (bind(m_sockfd,(struct sockaddr*)&m_serveraddr,sizeof(struct sockaddr)) != 0) {
        perror("bind");
        return 0;
    }
    
    // 开一个线程 去执行搜索的功能
    [NSThread detachNewThreadSelector:@selector(startSearchingThread) toTarget:self withObject:nil];
    printf("startUDP, socketfd = %d.......\n",m_sockfd);
    
    return 0;
}

-(void)stopUDPConnect
{
    self.recvSignal = false;
    close(m_sockfd);
    m_sockfd = -1;
}
- (void)startSearchingThread
{
    // 搜索 先发一个广播包。向局域网端口广播 UDP, 手机发一个广播包 给嵌入式设备，设备才会去做响应
    [self sendSearchBroadCast];
    
    // 嵌入式设备收到广播 返回 IP地址 端口，设备信息
    usleep(1 * 1000); // //停留1毫秒
    [self recvDataAndProcess];
    
}

// 发送广播包

-(BOOL)sendSearchBroadCast
{
    printf("发送广播包.......\n");
    
    char guangbo[1] = {};
    guangbo[0] = 88;
    if ([self sendData:(char *)&guangbo length:sizeof(guangbo)]) {
        printf("发送成功\n");
        return true;
    }
    return false;
    
//    bzero(guangbo, sizeof(guangbo));
//    ssize_t len;
//    len = sendto(m_sockfd, guangbo, strlen(guangbo), 0, (struct sockaddr *)&m_serveraddr, sizeof(m_serveraddr));
//
//    if (len > 0) {
//        printf("发送成功\n");
//        return true;
//    } else {
//        printf("发送失败\n");
//        return false;
//    }

}

-(BOOL)sendData:(char*)pBuf length:(int)length
{
    int sendLen = 0;
    ssize_t nRet = 0;
    socklen_t addrlen = 0;
    
    addrlen = sizeof(m_serveraddr);
    while (sendLen < length) {
        nRet = sendto(m_sockfd, pBuf, length, 0, (struct sockaddr*)&m_serveraddr, addrlen);
        
        if (nRet == -1) {
            perror("sendto error:\n");
            return false;
        }
        printf("发送了%ld个字符\n", nRet);
        sendLen += nRet;
        pBuf += nRet;
    }
    return true;
}

-(BOOL)recvData:(char*)pBuf length:(int)length
{
    int readLen=0;
    long nRet=0;
    socklen_t addrlen = sizeof(m_serveraddr);
    
    while(readLen<length)
    {
        nRet=recvfrom(m_sockfd,pBuf,length-readLen,0,(struct sockaddr*)&m_serveraddr,(socklen_t*)&addrlen);// 一直在搜索 阻塞，直到 接收到服务器的回复，即搜索到设备
        if(nRet==-1){
            perror("recvfrom error: \n");
            return false;
        }
        readLen+=nRet;
        pBuf+=nRet;
    }
    return true;
}

-(void)recvDataAndProcess
{
    while (_recvSignal) {
        HJ_MsgHeader msgHeader;
        memset(&msgHeader, 0, sizeof(msgHeader));
        // 读包头
        if([self recvData:(char *)&msgHeader length:sizeof(msgHeader)])
        {
            printf("header:%d    length:%d\n",msgHeader.headerIdentifying,msgHeader.contentLength);
            // ---- 来一份数据就向缓冲里追加一份 ----
            if (msgHeader.headerIdentifying == 134744072) {
                const size_t kRecvBufSize = msgHeader.contentLength;
                char* buf = (char*)malloc(kRecvBufSize * sizeof(char));
                
                int dataLength = msgHeader.contentLength;
//                printf("------ struct video len = %d\n",dataLength);
                if([self recvData:(char*)buf length:dataLength])
                {
                    if(nil == parser)
                    parser = [[VideoParser alloc] init];
                    [parser putVideoPacket:buf lenth:dataLength];
                }
            }
        }else{
            printf("接收失败");
        }
    }
    
}



@end
