package com.peer1.internetmap.network.Peer1;

import java.io.IOException;

import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Created by shayla on 2017-05-10.
 */

public class Peer1Client {
    static private final String BASE_URL = "http://asnl.peer1.com/v1/";
    private static Peer1API instance;

    public static Peer1API getInstance() {
        if (instance == null) {
            instance = getClient();
        }

        return instance;
    }

    static private Peer1API getClient() {
        // only set the HttpClient if it is null

        OkHttpClient httpClient = getHttpClient();

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(BASE_URL)
                .addConverterFactory(GsonConverterFactory.create())
                .client(httpClient)
                .build();

        return retrofit.create(Peer1API.class);
    }

    static private OkHttpClient getHttpClient() {

        HttpLoggingInterceptor httpLoggingInterceptor = new HttpLoggingInterceptor();
        httpLoggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);

        OkHttpClient.Builder builder = new OkHttpClient.Builder()
                //.readTimeout(10, TimeUnit.SECONDS)  // <-- Look into these options
                //.connectTimeout(5, TimeUnit.SECONDS)// <-- Look into these options
                .addInterceptor(new Interceptor() {
                    public Response intercept(Chain chain) throws IOException {
                        Request.Builder ongoing = chain.request().newBuilder();
                        ongoing.addHeader("Accept", "application/json;versions=1");

                        // TODO add
//                      ongoing.addHeader("Authorization", "Bearer " + getFacebookToken());

                        return chain.proceed(ongoing.build());
                    }
                });

        builder.addInterceptor(httpLoggingInterceptor);
        return builder.build();
    }
}
