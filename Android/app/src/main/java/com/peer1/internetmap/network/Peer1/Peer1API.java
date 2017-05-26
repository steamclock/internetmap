package com.peer1.internetmap.network.Peer1;

import retrofit2.Call;
import retrofit2.http.GET;

/**
 * Created by shayla on 2017-05-10.
 */

public interface Peer1API {

    @GET("ip")
    Call<String> getGlobalIP();

}
