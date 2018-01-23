//
//  FileParser.h
//  HdVideo
//
//  Created by 小宝左 on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef FileParser_h
#define FileParser_h
@interface FileParser : NSObject {

}
@property uint8_t* buffer;
@property NSInteger size;
@property NSString *fileName;
@property NSInputStream *fileStream;

+(FileParser *)GetInstance;
-(BOOL)open:(NSString *)fileName;
-(BOOL)createFile:(NSString *)filename;
-(FileParser*)nextPacket;
-(void)close;
@end

#endif /* FileParser_h */
