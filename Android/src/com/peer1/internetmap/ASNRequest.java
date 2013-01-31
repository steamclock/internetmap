package com.peer1.internetmap;

import java.io.UnsupportedEncodingException;

import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.AsyncHttpResponseHandler;
import org.apache.http.entity.StringEntity;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Requests the user's ASN from the internet.
 *
 * to get the ASN, call ASNRequest.fetchCurrentASNWithResponseHandler()
 * and pass in your ASNResponseHandler (which is almost the same as AsyncHttpResponseHandler, but returns a JSONObject on success)
 *
 */
public class ASNRequest {
    //this uses loopj-async-http-request
    //http://loopj.com/android-async-http/
    
    public interface ASNResponseHandler {
        public void onStart();
        public void onFinish();
        public void onSuccess(JSONObject response);
        public void onFailure(Throwable error, String content);
    }

    private static final String BASE_URL = "http://72.51.24.24:8080/";

    private static final AsyncHttpClient client = new AsyncHttpClient();

    private static String getAbsoluteUrl(String relativeUrl) {
        return BASE_URL + relativeUrl;
        //return BASE_URL + "invalid";
    }

    private static void fetchGlobalIPWithResponseHandler(AsyncHttpResponseHandler handler) {

        client.get(getAbsoluteUrl("ip"), handler);
    }
    
    private static void fetchASNForIP(String ip, final ASNResponseHandler finHandler) throws JSONException, UnsupportedEncodingException {
        JSONObject postData = new JSONObject();
        postData.put("ip", ip);
        StringEntity entity = new StringEntity(postData.toString());
        entity.setContentType("application/json");
        client.post(null, getAbsoluteUrl("iptoasn"), entity, "application/json", new AsyncHttpResponseHandler(){
            @Override
            public void onSuccess(String response) {
                try {
                    finHandler.onSuccess(new JSONObject(response));
                } catch (JSONException e) {
                    onFailure(new Throwable(e.getMessage()), null);
                }
            }
            @Override
            public void onFailure(Throwable error, String content) {
                finHandler.onFailure(error, content);
            }
            @Override
            public void onFinish() {
                finHandler.onFinish();
            }
        });
    }

    public static void fetchCurrentASNWithResponseHandler(final ASNResponseHandler finHandler) {
        //TODO: check the network connection first.
        fetchGlobalIPWithResponseHandler(new AsyncHttpResponseHandler() {

            @Override
            public void onStart(){
                finHandler.onStart();
            }

            @Override
            public void onSuccess(String response) {
                String errorString = "Couldn't resolve current global IP.";
                if (response != null && !response.isEmpty()) {
                    try {
                        JSONObject jsonObject = new JSONObject(response);
                        String ip = jsonObject.getString("payload");
                        if (ip != null && !ip.isEmpty()) {
                            fetchASNForIP(ip, finHandler);
                        } else {
                            onFailure(new Throwable(errorString), null);
                        }
                    } catch (Exception e) {
                        onFailure(new Throwable(e.getMessage()), null);
                    }

                }else {
                    onFailure(new Throwable(errorString), null);
                }
            }

            @Override
            public void onFailure(Throwable error, String content) {
                finHandler.onFailure(error, content);
                //if request #1 failed, then request #2 never started, so we're responsible for cleanup.
                finHandler.onFinish();
            }
        });

    }

}
