//
//  SCIcmpPacketUtility.m
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "SCIcmpPacketUtility.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

#pragma - SCPacketUtility

@interface SCIcmpPacketUtility ()

@property (nonatomic, copy,   readwrite) NSData*    targetAddress;
@property (nonatomic, assign, readwrite) uint16_t   nextSequenceNumber;

- (void)_stopHostResolution;
- (void)_stopDataTransfer;

@end

@implementation SCIcmpPacketUtility


@end
