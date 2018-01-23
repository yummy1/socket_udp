//
//  MMH264Decoder.h
//  HSVideoUDP
//
//  Created by MM on 2017/12/22.
//  Copyright © 2017年 MM. All rights reserved.
//

//  视频解码

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

typedef void (^ReturnDecodedVideoDataBlock) (CVPixelBufferRef pixelBuffer);

@interface MMH264Decoder : NSObject

@property (nonatomic, copy) ReturnDecodedVideoDataBlock returnDataBlock;

-(void)startH264DecodeWithVideoData:(char *)videoData andLength:(int)length andReturnDecodedData:(ReturnDecodedVideoDataBlock)block;
-(void)stopH264Decode;
@end
