package com.peer1.internetmap.network.common;

import android.content.Context;

import com.peer1.internetmap.R;
import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.models.GlobalIP;
import com.peer1.internetmap.models.MxASNInfo;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Call;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Retrofit Client (Singleton)
 * A central location to make requests and handle responses; responsible for setting up Retrofit
 * instance and handling all API requests.
 * <p>
 * @see CommonAPI
 */
public class CommonClient {

    /**
     * Singleton instance
     */
    static private CommonClient instance;
    public static CommonClient getInstance() {
        if (instance == null) {
            instance = new CommonClient();
        }
        return instance;
    }

    /**
     * Retrofit interface
     */
    private CommonAPI api;
    public CommonAPI getApi() {
        if (api == null) {
            api = createAPIInterface();
        }

        return api;
    }

    private retrofit2.Response<ASN> cachedUserASNResponse;

    //=====================================================================
    // Private methods
    //=====================================================================

    /**
     * Creates OkHttpClient and sets up Retrofit client.
     * @return Initialized CommonAPI interface
     */
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

    /**
     * Initializes OkHttpClient to be used by Retrofit
     * @return
     */
    private OkHttpClient createHttpClient() {

        HttpLoggingInterceptor httpLoggingInterceptor = new HttpLoggingInterceptor();
        httpLoggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);

        OkHttpClient.Builder builder = new OkHttpClient.Builder();
                //.readTimeout(10, TimeUnit.SECONDS)  // <-- Look into these options
                //.connectTimeout(5, TimeUnit.SECONDS)// <-- Look into these options

        builder.addInterceptor(httpLoggingInterceptor);
        return builder.build();
    }

    //=====================================================================
    // Public API methods
    //=====================================================================
    /**
     * Request the ASN for the user's current location.
     * @param callback Callback onRequestResponse will receive the ASN based on the Global IP Address of the device
     *                 onRequestFailure called if an error occurs during ASN determination.
     */
    public void getUserASN(final CommonCallback<ASN> callback) {

        if (cachedUserASNResponse != null) {
            callback.onResponse(null, cachedUserASNResponse);
            return;
        }

        getApi().getGlobalIP().enqueue(new CommonCallback<GlobalIP>() {
            @Override
            public void onRequestResponse(retrofit2.Call<GlobalIP> call, retrofit2.Response<GlobalIP> response) {

                getApi().getASNFromIP(response.body().ip).enqueue(new CommonCallback<ASN>() {
                    @Override
                    public void onRequestResponse(retrofit2.Call<ASN> call, retrofit2.Response<ASN> response) {
                        // TODO save in local storage instead?
                        cachedUserASNResponse = response;
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
