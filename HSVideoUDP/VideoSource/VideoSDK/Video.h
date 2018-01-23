//
//  Video.h
//  04.XML解析
//
//  Created by 刘凡 on 14-4-26.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Video : NSObject

@property (nonatomic, strong) NSNumber *videoId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSNumber *length;
@property (nonatomic, copy) NSString *videoURL;
@property (nonatomic, copy) NSString *imageURL;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *teacher;

//@property (nonatomic, strong) UIImage *image;
@end
