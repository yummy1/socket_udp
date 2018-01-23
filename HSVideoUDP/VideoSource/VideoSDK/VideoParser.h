//
//  VideoParser.h
//  HdVideo
//
//  Created by MM on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef VideoParser_h
#define VideoParser_h
@interface VideoParser:NSObject{

}
@property uint8_t* buffer;
@property NSInteger size;

+(VideoParser *)GetInstance;
-(void)putVideoPacket:(uint8_t *)buff lenth:(int) lenth;
-(VideoParser*)getVideoPacket;
@end

#endif /* VideoParser_h */
