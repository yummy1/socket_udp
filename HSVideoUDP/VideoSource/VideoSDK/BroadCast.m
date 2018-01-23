//
//  BoadCast.m
//  HdVideo
//
//  Created by 小宝左 on 16/9/21.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BroadCast.h"
#import <UIKit/UIKit.h>
#import "XmlPro.h"

@interface BroadCastServer(){
    bool connected;
    int fd;
}

@end
static BroadCastServer *Instance = nil;
@implementation BroadCastServer

+(BroadCastServer *)GetInstance{
    if(nil == Instance){
        Instance = [[BroadCastServer alloc]init];
        Instance->fd = 0;
        Instance->connected = NO;
    }
    
    return Instance;
}

-(BOOL)CreatSocket:(NSString *)addr{
    int ret = -1;
    int sock = -1;
    int j = -1;
    int so_broadcast = 1;
    struct ifreq *ifr;
    struct ifconf ifc;
    struct sockaddr_in broadcast_addr; //广播地址
    struct sockaddr_in from_addr; //服务端地址
    int from_len = sizeof(from_addr);
    int count = -1;
    fd_set readfd; //读文件描述符集合
    char buffer[1024];
    struct timeval timeout;
    timeout.tv_sec = 2; //超时时间为2秒
    timeout.tv_usec = 0;
    
    //建立数据报套接字
    BroadCastServer *Instance = [BroadCastServer GetInstance];
    Instance->fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (Instance->fd < 0)
    {
        perror("create socket failed:");
        return NO;
    }
    
    // 获取所有套接字接口
    ifc.ifc_len = sizeof(buffer);
    ifc.ifc_buf = buffer;
    if (ioctl(Instance->fd, SIOCGIFCONF, (char *) &ifc) < 0)
    {
        perror("ioctl-conf:");
        return NO;
    }
    ifr = ifc.ifc_req;
    for (j = ifc.ifc_len / sizeof(struct ifreq); --j >= 0; ifr++){
        if (!strcmp(ifr->ifr_name, "eth0")){
            if (ioctl(Instance->fd, SIOCGIFFLAGS, (char *) ifr) < 0){
                perror("ioctl-get flag failed:");
            }
            break;
        }
    }
    
    //将使用的网络接口名字复制到ifr.ifr_name中，由于不同的网卡接口的广播地址是不一样的，因此指定网卡接口
    //strncpy(ifr.ifr_name, IFNAME, strlen(IFNAME));
    //发送命令，获得网络接口的广播地址
    if (ioctl(Instance->fd, SIOCGIFBRDADDR, ifr) == -1){
        perror("ioctl error");
        return NO;
    }
    //将获得的广播地址复制到broadcast_addr
    memcpy(&broadcast_addr, (char *)&ifr->ifr_broadaddr, sizeof(struct sockaddr_in));
    //广播地址239.255.255.250端口号3702
    broadcast_addr.sin_addr.s_addr = inet_addr("239.255.255.250");
    broadcast_addr.sin_family = AF_INET;
    broadcast_addr.sin_port = htons(3702);
    
    //默认的套接字描述符sock是不支持广播，必须设置套接字描述符以支持广播
    ret = setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &so_broadcast,sizeof(so_broadcast));
    if(ret < 0)
        return NO;
    Instance->connected = true;
    return YES;
}

-(BOOL)CloseBraod{
    BroadCastServer *Instance = [BroadCastServer GetInstance];
    close(Instance->fd);
    Instance->fd = 0;
    Instance->connected = false;
    return YES;
}

-(BOOL)GetInfo{
    BroadCastServer *Instance = [BroadCastServer GetInstance];
    if(!Instance->connected){
        return NO;
    }
    XmlPro *pXmlPro = [XmlPro GetInstance];
    
    NSData *data=[pXmlPro getXmlData:@"getInfo"];
    if(nil == data){
        return NO;
    }
    //发送多次广播，看网络上是否有服务器存在
    int times = 10;
    int i = 0;
    struct timeval timeout;
    for (i = 0; i < times; i++)
    {
        //一共发送10次广播，每次等待2秒是否有回应
        //广播发送服务器地址请求
        timeout.tv_sec = 2;  //超时时间为2秒
        timeout.tv_usec = 0;
        struct sockaddr_in broadcast_addr; //广播地址
        broadcast_addr.sin_addr.s_addr = inet_addr("239.255.255.250");
        broadcast_addr.sin_family = AF_INET;
        broadcast_addr.sin_port = htons(3702);
        BroadCastServer *Instance = [BroadCastServer GetInstance];
        char buffer[1024];
        size_t ret = sendto(Instance->fd,data.bytes,data.length, 0,
                     (struct sockaddr*) &broadcast_addr, sizeof(broadcast_addr));
        //size_t ret=send(Instance->fd, data.bytes, data.length, MSG_DONTWAIT);
        if (ret == -1)
        {
            continue;
        }
        
        //文件描述符清0
        fd_set readfd; //读文件描述符集合
        FD_ZERO(&readfd);
        //将套接字文件描述符加入到文件描述符集合中
        FD_SET(Instance->fd, &readfd);
        //select侦听是否有数据到来
        ret = select(Instance->fd + 1, &readfd, NULL, NULL, &timeout);
        switch (ret)
        {
            case -1:
                break;
            case 0:
                perror("select timeout\n");
                break;
            default:
                //接收到数据
                if (FD_ISSET(Instance->fd,&readfd))
                {
                    size_t count = recvfrom(Instance->fd, buffer, 1024, 0,
                                     (struct sockaddr*) &broadcast_addr, sizeof(broadcast_addr)); //from_addr为服务器端地址
                    printf("\trecvmsg is %s\n", buffer);
                    /*
                    if (strstr(buffer, IP_FOUND_ACK))
                    {
                        printf("\tfound server IP is %s, Port is %d\n",
                               inet_ntoa(from_addr.sin_addr),
                               htons(from_addr.sin_port));
                    }
                     */
                    return -1;
                    
                }
                break;
                
        }
    }
    return 0;
    return YES;
}

@end
