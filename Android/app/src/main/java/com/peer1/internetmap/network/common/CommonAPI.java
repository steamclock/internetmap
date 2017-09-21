package com.peer1.internetmap.network.common;

import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.models.ASNIPs;
import com.peer1.internetmap.models.GlobalIP;
import com.peer1.internetmap.models.MxASNInfo;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Path;
import retrofit2.http.Query;

/**
 * Interface used to setup Retrofit API call
 * <p>
 * @see CommonClient
 */
public interface CommonAPI {

    /**
     * Get the GlobalIP of the current device
     * <p>
     * Using https://www.ipify.org/ to grab external IP
     * As of 2017-05-10, service was free for use without limit
     *
     * NOTE Current SSL issue on some devices: https://github.com/steamclock/internetmap/issues/475
     * Use http until this issue is fixed.
     */
    @GET("http://api.ipify.org?format=json")
    Call<GlobalIP> getGlobalIP();

    /**
     * Get the Autonomous System Number (ASN) for a given IP Address
     * <p>
     * @param ip The IP address
     * @return Call will return an ASN object which contains information about the AS.
     */
    @GET("https://internetmap-server.herokuapp.com/?req=iptoasn")
    Call<ASN> getASNFromIP(@Query("ip") String ip);

    /**
     * Get a list of IPs controlled by a given Autonomous System (AS) number.
     * EXAMPLE CALL: https://internetmap-server.herokuapp.com/?req=asntoips&asn=4565
     * RESULT: {"resultsPayload":"205.166.253.0/24"}
     */
    @GET("https://internetmap-server.herokuapp.com/?req=asntoips")
    Call<ASNIPs> getIPsFromASN(@Query("asn") String asn);



    // EXAMPLE CALL: https://internetmap-server.herokuapp.com/?req=asntoips&asn=4565
//// RESULT: {"resultsPayload":"205.166.253.0/24"}
//+(void)fetchIPsForASN:(NSString*)asn response:(ASNArrayResponseBlock)response {
//
//        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://internetmap-server.herokuapp.com/?req=asntoips&asn=%@", asn]]];
//    [request setTimeOutSeconds:TIMEOUT];
//    [request setRequestMethod:@"GET"];
//    [request addRequestHeader:@"Content-Type" value:@"application/json"];
//
//        __weak ASIFormDataRequest* weakRequest = request;
//
//    [request setCompletionBlock:^{
//            NSError* error = weakRequest.error;
//            NSDictionary* jsonResponse = [NSJSONSerialization JSONObjectWithData:weakRequest.responseData options:NSJSONReadingAllowFragments error:&error];
//            NSString* ipString = [jsonResponse objectForKey:@"resultsPayload"];
//
//            NSMutableArray* responseArray = [NSMutableArray array];
//
//            NSRange range = [ipString rangeOfString:@"/"];
//
//            if (range.location != NSNotFound) {
//                ipString = [ipString substringToIndex:range.location];
//            }
//
//            if (![ASNRequest isInvalidOrPrivate:ipString]) {
//            [responseArray addObject:ipString];
//            } else {
//                NSLog(@"Failed to add %@, was reserved IP.", ipString);
//            }
//
//            response(responseArray);
//
//        }];
//
//    [request setFailedBlock:^{
//            response(nil);
//        }];
//
//    [request start];
//    }

}
