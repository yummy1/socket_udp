//
//  configService.h
//  HdVideo
//
//  Created by 小宝左 on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef configService_h
#define configService_h

struct radiorate{
    char*   lable;
    int     x;
    int     y;
};
@interface ConfigService : NSObject{
    //NSString *ip;
}//私有变量，
@property(nonatomic, strong) NSString *ip;
@property(nonatomic) NSInteger framerate;    //5-60,帧率
@property(nonatomic) NSInteger gop;          //5-300,ms,关键帧间隔
@property(nonatomic) BOOL same_as;           //和输入源分辨率相同
@property(nonatomic) NSInteger  ratindex;    //取值0-7对应rat表
@property(nonatomic) BOOL rc_mode;           //0 定码率 1 编码率
@property(nonatomic) NSInteger profile;      //图像质量 0 低 1 中 2 高
@property(nonatomic) NSInteger rates;         //码率 500-4000
@property(nonatomic, strong) NSString  *version;

@property(nonatomic,strong)NSString *dataip;//获取的IP地址
+(ConfigService *)GetInstance;
-(void)SaveConfig;
-(void)LoadConfig;
-(char *)getRateLable;
-(char *)getDecodeTypeLable;
-(char *)getProfile;
@end


#endif /* configService_h */
