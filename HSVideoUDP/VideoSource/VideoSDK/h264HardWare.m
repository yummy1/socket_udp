//
//  h264HardWare.m
//  HdVideo
//
//  Created by MM on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "h264HardWare.h"
#import "SdkClient.h"
#import "Video.h"
//#import "AlertShow.h"
@interface h264HardWare(){
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}
@end
static h264HardWare *Instance;

@implementation h264HardWare

+(h264HardWare *)GetInstance{
    if(Instance == NULL){
        Instance = [[h264HardWare alloc]init];
    }
    return Instance;
}

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    //SdkClient *Client = [SdkClient GetInstance];
    //[Client RegisterCallBack:nil];
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
        return NO;
    }
    
    return YES;
}
-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}


- (void)resetH264Decoder
{
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    

    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    if(VTDecompressionSessionCanAcceptFormatDescription(_deocderSession, _decoderFormatDescription))
    {
        NSLog(@"yes");
    }
    
    OSStatus status = VTDecompressionSessionCreate(kCFAllocatorSystemDefault,
                                                   _decoderFormatDescription,
                                                   NULL, attrs,
                                                   &callBackRecord,
                                                   &_deocderSession);
    CFRelease(attrs);
}

-(CVPixelBufferRef)decode:(VideoParser*)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,(void*)vp.buffer, vp.size,kCFAllocatorNull,NULL, 0, vp.size,0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT1: Invalid session, reset decoder session");
                [self resetH264Decoder];
                printf("reset 264...\n");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT2: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT3: decode failed 。。。 status=%d －－－", decodeStatus);
                //[AlertShow ShowDecodeMessage:"IOS8VT: decode failed status=%d\n",decodeStatus];
            }
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    return outputPixelBuffer;
}

-(CVPixelBufferRef)decodeFile:(FileParser*)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)vp.buffer, vp.size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, vp.size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT4: Invalid session, reset decoder session");
                [self resetH264Decoder];
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT5: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT6: decode failed status=%d", decodeStatus);
            }
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    //NSLog(@"outputPixelBuffer : %p\n",outputPixelBuffer);
    return outputPixelBuffer;
}

//NSLog(@"start decode------\n");
-(CVPixelBufferRef)Decode2pixeBufer:(VideoParser *)hvp{
    uint32_t nalSize = (uint32_t)(hvp.size - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    hvp.buffer[0] = *(pNalSize + 3);
    hvp.buffer[1] = *(pNalSize + 2);
    hvp.buffer[2] = *(pNalSize + 1);
    hvp.buffer[3] = *(pNalSize);

    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = hvp.buffer[4] & 0x1F;
    switch (nalType) {
        case 0x05:
            //NSLog(@"Nal type is IDR frame");
            if([Instance initH264Decoder]) {
                pixelBuffer = [Instance decode:hvp];
            }
            break;
        case 0x07:
            //NSLog(@"Nal type is SPS");
            _spsSize = hvp.size - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, hvp.buffer + 4, _spsSize);
            break;
        case 0x08:
            //NSLog(@"Nal type is PPS");
            _ppsSize = hvp.size - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, hvp.buffer + 4, _ppsSize);
            break;
        default:
            //NSLog(@"Nal type is B/P frame");
            pixelBuffer = [Instance decode:hvp];
            break;
    }
    return pixelBuffer;
}


@end
