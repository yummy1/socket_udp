//
//  Video.m
//  04.XML解析
//
//  Created by 刘凡 on 14-4-26.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "Video.h"

@implementation Video

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ : %p> { videoId : %@, name : %@, length : %@, videoURL : %@, imageURL : %@, desc : %@, teacher : %@}", [self class], self, self.videoId, self.name, self.length, self.videoURL, self.imageURL, self.desc, self.teacher];
}

@end
