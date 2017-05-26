package com.peer1.internetmap.network.common;

/**
 * Created by shayla on 2017-05-15.
 */

public interface SimpleCallback<T> {
    void onSuccess(T result);
    void onFailure();
}
