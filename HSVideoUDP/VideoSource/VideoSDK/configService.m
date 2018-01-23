//
//  configService.m
//  HdVideo
//
//  Created by 小宝左 on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configService.h"
struct radiorate rate[]={
    {"1920x1080",1920,1080},
    {"1680x1056",1680,1056},
    {"1280x720", 1280, 720},
    {"1024x576", 1024, 576},
    {"850x480",   850, 480},
    {"720x576",   720, 675},
    {"720x540",   850, 480},
    {"720x480",   720, 480},
};

@interface ConfigService(){

}

@end
static ConfigService* pService=nil;
@implementation ConfigService;

@synthesize ip;
@synthesize framerate;    //5-60,帧率
@synthesize gop;          //5-300,ms,关键帧间隔
@synthesize same_as;      //和输入源分辨率相同
@synthesize ratindex;     //取值0-7对应rat表
@synthesize rc_mode;      //0 定码率 1 编码率
@synthesize profile;      //图像质量 0 低 1 中 2 高
@synthesize rates;
@synthesize version;      //版本

+(ConfigService *)GetInstance{
    if(pService == nil){
        pService= [[ConfigService alloc]init];
        [pService LoadConfig];
        if(pService->ip == nil){
            [pService SaveConfigDef];
        }
    }
    return pService;
}

-(void)SaveConfig{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    if(nil == pService){
        [ConfigService GetInstance];
    }
    [defaults setObject:pService->ip forKey:@"CFBundle_KV_ip"];
    [defaults setInteger:pService->framerate forKey:@"framerate"];
    [defaults setInteger:pService->gop forKey:@"gop"];
    [defaults setBool:pService->same_as forKey:@"same_as"];
    [defaults setInteger:pService->ratindex forKey:@"ratindex"];
    [defaults setBool:pService->rc_mode forKey:@"rc_mode"];
    [defaults setInteger:pService->profile forKey:@"profile"];
    [defaults synchronize];
}

-(void)LoadConfig{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    if(nil == pService){
        [ConfigService GetInstance];
    }
    pService->ip=[defaults objectForKey:@"CFBundle_KV_ip"];
    pService->framerate=[defaults integerForKey:@"framerate"];
    pService->gop=[defaults integerForKey:@"gop"];
    pService->same_as=[defaults boolForKey:@"same_as"];
    pService->ratindex=[defaults integerForKey:@"ratindex"];
    pService->rc_mode=[defaults boolForKey:@"rc_mode"];
    pService->profile=[defaults integerForKey:@"profile"];
}

-(void)SaveConfigDef{
    if(nil == pService){
        [ConfigService GetInstance];
    }
//    [[NSUserDefaults standardUserDefaults] objectForKey:@"CFBundle_KV_ip"];
    pService->ip = [[NSUserDefaults standardUserDefaults] objectForKey:@"CFBundle_KV_ip"];
    NSLog(@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"CFBundle_KV_ip"]);
    pService->framerate=25;
    pService->gop=25;
    pService->same_as=0;
    pService->ratindex=0;
    pService->rc_mode=1;
    pService->profile=2;
    pService->rates=2000;
    [pService SaveConfig];
}

-(char *)getRateLable{
    if(nil == pService){
        [ConfigService GetInstance];
    }
    return  rate[pService->framerate%(sizeof(rate)/sizeof(rate[0]))].lable;
}

-(char *)getDecodeTypeLable{
    if(nil == pService){
        [ConfigService GetInstance];
    }
    return  pService->rc_mode==1?"定码率":"变码率";
}

-(char *)getProfile{
    if(nil == pService){
        [ConfigService GetInstance];
    }
    switch (pService->profile) {
        case 0:
            return "高";
        case 1:
            return "中";
        case 2:
            return "低";
        default:
            return "未知";
    }
}
@end
