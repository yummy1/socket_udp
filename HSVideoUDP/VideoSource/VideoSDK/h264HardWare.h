//
//  h264HardWare.h
//  HdVideo
//
//  Created by MM on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef h264HardWare_h
#define h264HardWare_h
//#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>
#import "VideoParser.h"
#import "FileParser.h"
@interface h264HardWare:NSObject{
    
}

+(h264HardWare *)GetInstance;
-(BOOL)initH264Decoder;
-(void)clearH264Deocder;
-(CVPixelBufferRef)decodeFile:(FileParser*)vp;
-(CVPixelBufferRef)Decode2pixeBufer:(VideoParser *)hvp;
-(void)close;
@end

#endif
