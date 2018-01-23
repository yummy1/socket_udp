//
//  PingService.h
//  AjiGo
//
//  Created by 小宝左 on 16/5/27.
//  Copyright © 2016年 com.ajsx. All rights reserved.
//

#ifndef PingService_h
#define PingService_h
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Ping.h"

typedef NS_ENUM(NSInteger, PingStatus) {
    PingStatusDidStart,
    PingStatusDidReceivePacket,
    PingStatusDidTimeout,
    PingStatusFinished,
};

@interface PingItem : NSObject

@property(nonatomic) NSString *originalAddress;
@property(nonatomic, copy) NSString *IPAddress;

@property(nonatomic) NSUInteger dateBytesLength;
@property(nonatomic) double     timeMilliseconds;
@property(nonatomic) NSInteger  timeToLive;
@property(nonatomic) NSInteger  ICMPSequence;

@property(nonatomic) PingStatus status;

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems;

@end

@interface PingService : NSObject

/// 超时时间, default 500ms
@property(nonatomic) double timeoutMilliseconds;

+ (PingService *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(PingItem *pingItem, NSArray *pingItems))handler;

@property(nonatomic) NSInteger  maximumPingTimes;
- (void)cancel;

@end


#endif /* PingService_h */
