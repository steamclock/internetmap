//
//  SCPacketRecord.h
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCPacketRecord : NSObject

@property uint16_t sequenceNumber; //A sequence number for tracking of packet relationships as we perform network operations
@property int sentWithTTL; // The TTL that our original packet has assigned to it
@property NSString* responseAddress; //The address of the machine that sent us a respponse packet for this sequence number
@property NSDate* departure; // Departure time of packet sent for this sequence number
@property NSDate* arrival; // Arrive of response packet for this sequence number
@property float rtt; //The round trip time for the sequence, which is essentially (arrival - sent)
@property BOOL timedOut;


@end
