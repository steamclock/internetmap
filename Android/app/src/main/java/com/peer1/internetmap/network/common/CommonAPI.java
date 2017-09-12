package com.peer1.internetmap.network.common;

import com.peer1.internetmap.models.ASN;
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
     * https://iptoasn.com/
     * Free IP address to ASN database
     * Can also download DB and run local service
     * <p>
     * @param ip The IP address
     * @return Call will return an ASN object which contains information about the AS.
     */
    @GET("https://internetmap-server.herokuapp.com/?req=iptoasn")
    Call<ASN> getASNFromIP(@Query("ip") String ip);

    /**
     * Get a list of IPs controlled by a given Autonomous System (AS) number.
     * <p>
     * TODO switch to use https://internetmap-server.herokuapp.com/?req=asntoips&asn=4565
     */
    //@GET("https://api.mxtoolbox.com/api/v1/lookup/asn/as{asn}")
    //Call<MxASNInfo> getIPFromASN(@Path("asn") String asn, @Query("authorization") String auth);
}
