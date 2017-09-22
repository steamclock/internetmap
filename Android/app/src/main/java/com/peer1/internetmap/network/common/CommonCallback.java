package com.peer1.internetmap.network.common;

import com.peer1.internetmap.App;
import com.peer1.internetmap.utils.AppUtils;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import timber.log.Timber;

/**
 * Custom retrofit {@linkplain retrofit2.Callback Callback}
 * @param <T>
 * Used mostly by {@linkplain CommonClient CommonClient} to allow us to control the data passed
 * back from our Retrofit calls
 */
public abstract class CommonCallback<T> implements Callback<T> {

    public CommonCallback() {
        super();
    }

    public void onResponse(Call<T> call, Response<T> response) {

        //T responseObject = response.body();
        int code = response.code();

        switch (code) {
            // OK!
            case 200:
                onRequestResponse(call, response);
                break;

            // Unauthorized
            //case 401: // If we need to handle auth issue

            default:
                onRequestFailure(call, new Throwable(String.valueOf(code)));
                break;
        }
    }

    public void onFailure(Call<T> call, Throwable t) {

        if (!App.hasConnection()) {
            App.showNoConnectionFeedback();
        }

        try {
            String url = call.request().url().toString();
            Timber.e(String.format("Call (%s) failed: %s", url, t.getMessage()));
        } catch (Exception e) {
            Timber.e(t);
        }

        onRequestFailure(call,t);
    }

    abstract public void onRequestResponse(Call<T> call, Response<T> response);

    abstract public void onRequestFailure(Call<T> call, Throwable t);

}
