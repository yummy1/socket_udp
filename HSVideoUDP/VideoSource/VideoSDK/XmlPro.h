//
//  XmlPro.h
//  HdVideo
//
//  Created by 小宝左 on 16/9/18.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#ifndef XmlPro_h
#define XmlPro_h
@interface XmlPro:NSObject

@property (nonatomic,   strong) NSNumber        *videoId;
@property (nonatomic,   strong) NSMutableArray  *notes;
@property (nonatomic,   strong) NSString        *curtag;
-(void)start;
//@property (nonatomic, strong) UIImage *image;
-(NSData *)InitXmlParser:(NSString *)file;
+(XmlPro *)GetInstance;
-(NSData *)getXmlData:(NSString *)xmlfile;
@end



#endif /* XmlPro_h */
