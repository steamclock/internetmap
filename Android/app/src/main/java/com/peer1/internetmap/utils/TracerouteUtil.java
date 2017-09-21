package com.peer1.internetmap.utils;

import android.util.Log;

import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.NodeWrapper;
import com.peer1.internetmap.ProbeWrapper;

import java.util.ArrayList;

/**
 * Created by shayla on 2017-09-20.
 */

public class TracerouteUtil {

    public interface Listener {
        void onHopFound(int ttl, String ip);
        void onTimeout(int ttl);
    }

    private MapControllerWrapper mapControllerWrapper;
    private ArrayList<String> result;
    private String traceDestination;
    private Listener listener;

    public TracerouteUtil(MapControllerWrapper mapControllerWrapper) {
        this.mapControllerWrapper = mapControllerWrapper;
        this.listener = new Listener() {
            @Override
            public void onHopFound(int ttl, String ip) {

            }

            @Override
            public void onTimeout(int ttl) {

            }
        };
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public void startTrace() {
        int maxHops = 255;
        traceDestination = "172.217.3.164";

        for (int ttl = 1; ttl < maxHops; ttl++) {

            ProbeWrapper probeWrapper = mapControllerWrapper.probeDestinationAddressWithTTL(traceDestination, ttl);

            if (probeWrapper.fromAddress != null) {
                Log.v("Trace HUZZAH", "WOOP " + probeWrapper.fromAddress);
                if (probeWrapper.fromAddress.equals(traceDestination)) {
                    listener.onHopFound(ttl, probeWrapper.fromAddress);
                    break;
                }
            } else {
                listener.onTimeout(ttl);
            }
        }
    }

    private void onFoundHop(String from) {

    }

    private void displayHops(ArrayList<String> traceIps) {

        ArrayList<NodeWrapper> mergedAsnHops;

        // TODO add our ASN at the start of the list.



    }

//
//- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray *)hops{
//
//        NSLog(@"%@", report);
//
//        self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\n%@", self.nodeInformationViewController.tracerouteTextView.text, report] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//
//    [self.nodeInformationViewController.box1 incrementNumber];
//
//        if ([hops count] <= 0) {
//            return;
//        }
//
//    [hops enumerateObjectsUsingBlock:^(NSString* ip, NSUInteger idx, BOOL *stop) {
//            if(ip && ![ip isEqual:[NSNull null]] && (self.tracerouteASNs[ip] == nil)) {
//            [ASNRequest fetchASNForIP:ip response:^(NSString *asn) {
//                    if(self.tracer == nil) {
//                        // occasionally we get a rogue one after the trace is finished, we can probably ignore that
//                        return;
//                    }
//
//                    if(asn && ![asn isEqual:[NSNull null]]) {
//                        self.tracerouteASNs[ip] = asn;
//                    }
//                else {
//                        self.tracerouteASNs[ip] = [NSNull null];
//                    }
//
//                [self displayHops:hops withDestNode:nil];
//                }];
//            }
//        }];
//    }


//    -(void)displayHops:(NSArray*)ips withDestNode:(NodeWrapper*)destNode {
//        NSMutableArray* mergedAsnHops = [NSMutableArray new];
//
//        __block NSString* lastAsn = nil;
//        __block NSInteger lastIndex = -1;
//
//        // Put our ASN at the start of the list, just in case
//        NodeWrapper* us = [self.controller nodeByASN:self.cachedCurrentASN];
//        if(us) {
//        [mergedAsnHops addObject:us];
//            lastAsn = self.cachedCurrentASN;
//        }
//
//    [ips enumerateObjectsUsingBlock:^(NSString* ip, NSUInteger idx, BOOL *stop) {
//            NSString* asn = self.tracerouteASNs[ip];
//            if(asn && ![asn isEqual:[NSNull null]] && ![asn isEqualToString:lastAsn])  {
//                lastAsn = asn;
//                NodeWrapper* node = [self.controller nodeByASN:asn];
//                if(node) {
//                    lastIndex = node.index;
//                [mergedAsnHops addObject:node];
//                }
//            }
//        }];
//
//        if(destNode && (lastIndex != destNode.index)) {
//        [mergedAsnHops addObject:destNode];
//        }
//
//        if ([mergedAsnHops count] >= 2) {
//        [self.controller highlightRoute:mergedAsnHops];
//        }
//
//        self.nodeInformationViewController.box2.numberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[mergedAsnHops count]];
//    }



}
