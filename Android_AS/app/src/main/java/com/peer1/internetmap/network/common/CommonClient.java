package com.peer1.internetmap.network.common;

import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.models.GlobalIP;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Created by shayla on 2017-05-10.
 */

public class CommonClient {

    static private CommonClient instance;
    public static CommonClient getInstance() {
        if (instance == null) {
            instance = new CommonClient();
        }
        return instance;
    }

    private CommonAPI api;
    public CommonAPI getApi() {
        if (api == null) {
            api = createAPIInterface();
        }

        return api;
    }

    private CommonAPI createAPIInterface() {
        // only set the HttpClient if it is null

        OkHttpClient httpClient = createHttpClient();

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("http://willnotbeused.com")
                .addConverterFactory(GsonConverterFactory.create())
                .client(httpClient)
                .build();

        return retrofit.create(CommonAPI.class);
    }

    private OkHttpClient createHttpClient() {

        HttpLoggingInterceptor httpLoggingInterceptor = new HttpLoggingInterceptor();
        httpLoggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);

        OkHttpClient.Builder builder = new OkHttpClient.Builder();
                //.readTimeout(10, TimeUnit.SECONDS)  // <-- Look into these options
                //.connectTimeout(5, TimeUnit.SECONDS)// <-- Look into these options

        builder.addInterceptor(httpLoggingInterceptor);
        return builder.build();
    }

    /**
     * Calls getGlobalIP and then getASNFromIP
     */
    public void getUserASN(final CommonCallback<ASN> callback) {

        getApi().getGlobalIP().enqueue(new CommonCallback<GlobalIP>() {
            @Override
            public void onRequestResponse(retrofit2.Call<GlobalIP> call, retrofit2.Response<GlobalIP> response) {

                getApi().getASNFromIP(response.body().ip).enqueue(new CommonCallback<ASN>() {
                    @Override
                    public void onRequestResponse(retrofit2.Call<ASN> call, retrofit2.Response<ASN> response) {
                        callback.onResponse(call, response);
                    }

                    @Override
                    public void onRequestFailure(retrofit2.Call<ASN> call, Throwable t) {
                        callback.onFailure(call, t);
                    }
                });

            }

            @Override
            public void onRequestFailure(retrofit2.Call<GlobalIP> call, Throwable t) {
                callback.onFailure(null, t);
            }
        });
    }
}
