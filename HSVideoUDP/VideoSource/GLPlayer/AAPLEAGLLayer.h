//
//  AAPLEAGLLayer.h
//  HSVideoUDP
//
//  Created by MM on 2017/12/22.
//  Copyright © 2017年 MM. All rights reserved.
//

//@import QuartzCore;
#include <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>

@interface AAPLEAGLLayer : CAEAGLLayer
@property CVPixelBufferRef pixelBuffer;
- (id)initWithFrame:(CGRect)frame;
- (void)resetRenderBuffer;
@end
