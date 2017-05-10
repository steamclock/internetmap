package com.peer1.internetmap.network.common;

import android.app.Activity;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import timber.log.Timber;


public abstract class CommonCallback<T> implements Callback<T> {

    public CommonCallback() {
        super();
    }

    public CommonCallback(Activity activity) {
        super();
    }

    public CommonCallback(final Activity activity, final String loadingString) {
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
            case 401:
                // Attempt to bounce back to login as we are no longer authorized
                // TODO
                // Not calling onRequestFailure?
                onRequestFailure(call, new Throwable("401"));
                break;

            // Errything else
            default:
               // TODO
                onRequestFailure(call, new Throwable(String.valueOf(code)));
                break;
        }
    }

    public void onFailure(Call<T> call, Throwable t) {
        Timber.e(String.format("Call (%s) failed: %s", call.request().url().toString(), t.getMessage()));
        onRequestFailure(call,t);
    }

    abstract public void onRequestResponse(Call<T> call, Response<T> response);

    abstract public void onRequestFailure(Call<T> call, Throwable t);

}
