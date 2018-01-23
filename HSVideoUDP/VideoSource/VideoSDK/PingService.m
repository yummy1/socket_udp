//
//  PingService.m
//  AjiGo
//
//  Created by 小宝左 on 16/5/27.
//  Copyright © 2016年 com.ajsx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PingService.h"

@implementation PingItem

- (NSString *)description {
    if (self.status == PingStatusDidStart) {
        return [NSString stringWithFormat:@"PING %@ (%@): %ld data bytes",self.originalAddress, self.IPAddress, (long)self.dateBytesLength];
    }
    if (self.status == PingStatusDidTimeout) {
        return [NSString stringWithFormat:@"Request timeout for icmp_seq %ld", (long)self.ICMPSequence];
    }
    if (self.status == PingStatusDidReceivePacket) {
        return [NSString stringWithFormat:@"%ld bytes from %@: icmp_seq=%ld ttl=%ld time=%.3f ms", (long)self.dateBytesLength, self.IPAddress, (long)self.ICMPSequence, (long)self.timeToLive, self.timeMilliseconds];
    }
    return super.description;
}

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems {
    //    --- baidu.com ping statistics ---
    //    5 packets transmitted, 5 packets received, 0.0% packet loss
    //    round-trip min/avg/max/stddev = 4.445/9.496/12.210/2.832 ms
    NSString *address = [pingItems.firstObject originalAddress];
    NSMutableString *description = [NSMutableString stringWithCapacity:50];
    [description appendFormat:@"--- %@ ping statistics ---\n", address];
    __block NSInteger receivedCount = 0;
    [pingItems enumerateObjectsUsingBlock:^(PingItem *obj, NSUInteger idx, BOOL *stop) {
        if (obj.status == PingStatusDidReceivePacket) {
            receivedCount ++;
        }
    }];
    NSInteger allCount = pingItems.count;
    CGFloat lossPercent = (CGFloat)(allCount - receivedCount) / MAX(1.0, allCount) * 100;
    [description appendFormat:@"%ld packets transmitted, %ld packet received, %.1f%% packet loss\n", (long)allCount, (long)receivedCount, lossPercent];
    return [description stringByReplacingOccurrencesOfString:@".0%" withString:@"%"];
}
@end

@interface PingService () <PingDelegate> {
    BOOL _hasStarted;
    BOOL _isTimeout;
    NSMutableArray *_pingItems;
}

@property(nonatomic, copy)   NSString   *address;
@property(nonatomic, strong) Ping *ping;

@property(nonatomic, strong)void(^callbackHandler)(PingItem *item, NSArray *pingItems);

@end

@implementation PingService

+ (PingService *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(PingItem *item, NSArray *pingItems))handler {
    PingService *services = [[PingService alloc] initWithAddress:address];
    services.callbackHandler = handler;
    [services startPing];
    return services;
}

- (instancetype)initWithAddress:(NSString *)address {
    self = [super init];
    if (self) {
        self.timeoutMilliseconds = 2000;
        self.address = address;
        self.ping = [Ping PingWithHostName:address];
        self.ping.delegate = self;
        self.maximumPingTimes = 100;
        //_icmpSequence = 1;
        _pingItems = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)startPing {
    _hasStarted = NO;
    [_pingItems removeAllObjects];
    [self.ping start];
}

- (void)reping {
    [self.ping stop];
    [self.ping start];
}

- (void)_timeoutActionFired {
    PingItem *pingItem = [[PingItem alloc] init];
    pingItem.originalAddress = self.address;
    pingItem.status = PingStatusDidTimeout;
    [self _handlePingItem:pingItem];
}

- (void)_handlePingItem:(PingItem *)pingItem {
    if (pingItem.status == PingStatusDidReceivePacket || pingItem.status == PingStatusDidTimeout) {
        [_pingItems addObject:pingItem];
    }

     if (self.callbackHandler) {
            self.callbackHandler(pingItem, [_pingItems copy]);
        }

    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(reping) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)cancel {
    [self.ping stop];
    PingItem *pingItem = [[PingItem alloc] init];
    pingItem.status = PingStatusFinished;
    if (self.callbackHandler) {
        self.callbackHandler(pingItem, [_pingItems copy]);
    }
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
}

- (void)Ping:(Ping *)pinger didStartWithAddress:(NSData *)address {
    [pinger sendPingWithData:nil];
    [self performSelector:@selector(_timeoutActionFired) withObject:nil afterDelay:self.timeoutMilliseconds / 1000.0];
}
// If this is called, the SimplePing object has failed.  By the time this callback is
// called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SimplePing icmpInPacket:]
// to find the ICMP header within the packet.

- (void)Ping:(Ping *)pinger didSendPacket:(NSData *)packet ICMPHeader:(ICMPHeader *)_ICMPHeader {
    
    PingItem *pingItem = [[PingItem alloc] init];
    pingItem.IPAddress = pinger.IPAddress;
    pingItem.originalAddress = self.address;
    pingItem.dateBytesLength = packet.length - sizeof(ICMPHeader);
    pingItem.status = PingStatusDidStart;
    if (self.callbackHandler && !_hasStarted) {
        self.callbackHandler(pingItem, nil);
        _hasStarted = YES;
    }
}

// Called whenever the SimplePing object tries and fails to send a ping packet.
- (void)Ping:(Ping *)pinger didReceivePingResponsePacket:(NSData *)packet timeElasped:(NSTimeInterval)timeElasped {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    const struct IPHeader * ipPtr = NULL;
    size_t                  ipHeaderLength = 0;
    if (packet.length >= (sizeof(IPHeader) + sizeof(ICMPHeader))) {
        ipPtr = (const IPHeader *) [packet bytes];
        ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);
    }
    NSInteger timeToLive = 0, dataBytesSize = 0;
    if (ipPtr != NULL) {
        dataBytesSize = packet.length - ipHeaderLength;
        timeToLive = ipPtr->timeToLive;
    }
    PingItem *pingItem = [[PingItem alloc] init];
    pingItem.IPAddress = pinger.IPAddress;
    pingItem.dateBytesLength = dataBytesSize;
    pingItem.timeToLive = timeToLive;
    pingItem.timeMilliseconds = timeElasped * 1000;
    pingItem.originalAddress = self.address;
    pingItem.status = PingStatusDidReceivePacket;
    [self _handlePingItem:pingItem];
}
@end
