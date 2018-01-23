//
//  FileParser.m
//  HdVideo
//
//  Created by 小宝左 on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileParser.h"
@interface FileParser(){

}
@end
const uint8_t KStartCode[4] = {0, 0, 0, 1};
uint8_t *_buffer;
NSInteger _bufferSize;
NSInteger _bufferCap;
static FileParser *Instance;
@implementation FileParser
+(FileParser *)GetInstance{
    if(nil == Instance)
        Instance =[[FileParser alloc]init];
    return Instance;
}


- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    return self;
}

-(BOOL)open:(NSString *)fileName
{
    _bufferSize = 0;
    _bufferCap = 512 * 1024;
    _buffer = malloc(_bufferCap);
    self.fileName = fileName;
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:fileName];
    [self.fileStream open];
    return YES;
}

-(BOOL)createFile:(NSString *)filename{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filename]){
        return YES;
    }
    
    
    return YES;
}

-(FileParser*)nextPacket
{
    if(_bufferSize < _bufferCap && self.fileStream.hasBytesAvailable) {
        NSInteger readBytes = [self.fileStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        _bufferSize += readBytes;
    }
    
    if(memcmp(_buffer, KStartCode, 4) != 0) {
        return nil;
    }
    
    if(_bufferSize >= 5) {
        uint8_t *bufferBegin = _buffer + 4;
        uint8_t *bufferEnd = _buffer + _bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - _buffer - 3;
                    FileParser *vp = [[FileParser alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _buffer, packetSize);
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    return nil;
}

-(void)close
{
    free(_buffer);
    [self.fileStream close];
}


@end

