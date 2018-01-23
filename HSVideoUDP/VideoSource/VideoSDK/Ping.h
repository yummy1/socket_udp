//
//  Ping.h
//  AjiGo
//
//  Created by 小宝左 on 16/5/27.
//  Copyright © 2016年 com.ajsx. All rights reserved.
//

#ifndef Ping_h
#define Ping_h
#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#include <AssertMacros.h>

#pragma mark * Ping

// The following declarations specify the structure of ping packets on the wire.

// IP header structure:

struct IPHeader {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
};
typedef struct IPHeader IPHeader;


// ICMP type and code combinations:

enum {
    kICMPTypeEchoReply   = 0,           // code is always 0
    kICMPTypeEchoRequest = 8            // code is always 0
};

// ICMP header structure:

struct ICMPHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};
typedef struct ICMPHeader ICMPHeader;

@protocol PingDelegate;

@interface Ping : NSObject
{
    NSString *              _hostName;
    NSData *                _hostAddress;
    CFHostRef               _host;
    CFSocketRef             _socket;
    id<PingDelegate>  __unsafe_unretained _delegate;
    uint16_t                _identifier;                            // host byte order
    uint16_t                _nextSequenceNumber;                    // host byte order
}

+ (Ping *)PingWithHostName:(NSString *)hostName;        // chooses first IPv4 address
+ (Ping *)PingWithHostAddress:(NSData *)hostAddress;    // contains (struct sockaddr)

@property (nonatomic, assign, readwrite) id<PingDelegate> delegate;

@property (nonatomic, copy,   readonly)  NSString *             hostName;
@property (nonatomic, copy,   readonly)  NSData *               hostAddress;
@property (nonatomic, assign, readonly)  uint16_t               identifier;
@property (nonatomic, assign, readonly)  uint16_t               nextSequenceNumber;
@property (nonatomic, copy) NSString *IPAddress;

- (void)start;
// Starts the pinger object pinging.  You should call this after
// you've setup the delegate and any ping parameters.

- (void)sendPingWithData:(NSData *)data;
// Sends an actual ping.  Pass nil for data to use a standard 56 byte payload (resulting in a
// standard 64 byte ping).  Otherwise pass a non-nil value and it will be appended to the
// ICMP header.
//
// Do not try to send a ping before you receive the -simplePing:didStartWithAddress: delegate
// callback.

- (void)stop;
// Stops the pinger object.  You should call this when you're done
// pinging.

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet;
// Given a valid IP packet contains an ICMP , returns the address of the ICMP header that
// follows the IP header.  This doesn't do any significant validation of the packet.

@end

@protocol PingDelegate <NSObject>

@optional

- (void)Ping:(Ping *)pinger didStartWithAddress:(NSData *)address;
// Called after the SimplePing has successfully started up.  After this callback, you
// can start sending pings via -sendPingWithData:

- (void)Ping:(Ping *)pinger didFailWithError:(NSError *)error;
// If this is called, the SimplePing object has failed.  By the time this callback is
// called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SimplePing icmpInPacket:]
// to find the ICMP header within the packet.

- (void)Ping:(Ping *)pinger didSendPacket:(NSData *)packet ICMPHeader:(ICMPHeader *)ICMPHeader;
// Called whenever the SimplePing object has successfully sent a ping packet.

- (void)Ping:(Ping *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error;
// Called whenever the SimplePing object tries and fails to send a ping packet.

- (void)Ping:(Ping *)pinger didReceivePingResponsePacket:(NSData *)packet timeElasped:(NSTimeInterval)timeElasped;
// Called whenever the SimplePing object receives an ICMP packet that looks like
// a response to one of our pings (that is, has a valid ICMP checksum, has
// an identifier that matches our identifier, and has a sequence number in
// the range of sequence numbers that we've sent out).

- (void)Ping:(Ping *)pinger didReceiveUnexpectedPacket:(NSData *)packet;
// Called whenever the SimplePing object receives an ICMP packet that does not
// look like a response to one of our pings.

@end



//check_compile_time(sizsof(IPHeader) == 20);
//check_compile_time(offsetof(IPHeader, versionAndHeaderLength) == 0);
//check_compile_time(offsetof(IPHeader, differentiatedServices) == 1);
//check_compile_time(offsetof(IPHeader, totalLength) == 2);
//check_compile_time(offsetof(IPHeader, identification) == 4);
//check_compile_time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
//check_compile_time(offsetof(IPHeader, timeToLive) == 8);
//check_compile_time(offsetof(IPHeader, protocol) == 9);
//check_compile_time(offsetof(IPHeader, headerChecksum) == 10);
//check_compile_time(offsetof(IPHeader, sourceAddress) == 12);
//check_compile_time(offsetof(IPHeader, destinationAddress) == 16);
//
//
//check_compile_time(sizeof(ICMPHeader) == 8);
//check_compile_time(offsetof(ICMPHeader, type) == 0);
//check_compile_time(offsetof(ICMPHeader, code) == 1);
//check_compile_time(offsetof(ICMPHeader, checksum) == 2);
//check_compile_time(offsetof(ICMPHeader, identifier) == 4);
//check_compile_time(offsetof(ICMPHeader, sequenceNumber) == 6);







#endif /* Ping_h */
