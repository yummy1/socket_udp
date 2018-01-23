//
//  ViewController.m
//  HSVideoUDP
//
//  Created by MM on 2017/12/22.
//  Copyright © 2017年 MM. All rights reserved.
//

#import "ViewController.h"
#import "MMUDPClient.h"
#import "VideoParser.h"
#import "h264HardWare.h"
#import "AAPLEAGLLayer.h"

@interface ViewController ()
@property (nonatomic,strong) MMUDPClient *client;
@property (nonatomic,strong) AAPLEAGLLayer *bfLayer;
@property (nonatomic, assign) BOOL  videoIsStop;        // 记录 视频是否在暂停的状态

@end

@implementation ViewController
#pragma mark - 懒加载
- (AAPLEAGLLayer *)bfLayer
{
    if (!_bfLayer) {
        _bfLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
        _bfLayer.backgroundColor = [UIColor redColor].CGColor;
    }
    return _bfLayer;
}
- (MMUDPClient *)client
{
    if (!_client) {
        _client = [[MMUDPClient alloc] init];
    }
    return _client;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //socket
    [self.client startUDPConnection];
    
    //视频
    [self.view.layer addSublayer:self.bfLayer];
    
    //解码
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakSelf decode264];
    });
}
-(void)decode264{
    VideoParser *videoParser;
    VideoParser *hvp;
    h264HardWare *h264Decoder;
    while(true) {
        if(h264Decoder == nil)
            h264Decoder = [h264HardWare GetInstance];
        
        if(videoParser == nil)
            videoParser = [VideoParser GetInstance];
        
        //printf("get package ...\n");
        hvp = [videoParser getVideoPacket];
        if(hvp == nil) {
            continue;
        }
        
        CVPixelBufferRef pixelBuffer = [h264Decoder Decode2pixeBufer:hvp];
        
        if(pixelBuffer) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"视频图像帧出现");
                _bfLayer.pixelBuffer = pixelBuffer;
            });
            CVPixelBufferRelease(pixelBuffer);
        }
    }
}





@end
