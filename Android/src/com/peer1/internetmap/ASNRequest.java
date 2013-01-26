package com.peer1.internetmap;

import android.content.Context;
import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.AsyncHttpResponseHandler;
import com.loopj.android.http.RequestParams;
import org.apache.http.entity.BasicHttpEntity;
import org.apache.http.entity.StringEntity;
import org.apache.http.message.BasicHeader;
import org.apache.http.protocol.HTTP;
import org.json.JSONException;
import org.json.JSONObject;
import org.xml.sax.InputSource;

import java.io.StringReader;
import java.io.UnsupportedEncodingException;

public class ASNRequest {
    //this uses loopj-async-http-request
    //http://loopj.com/android-async-http/

    private static final String BASE_URL = "http://72.51.24.24:8080/";

    private static final AsyncHttpClient client = new AsyncHttpClient();

    private static String getAbsoluteUrl(String relativeUrl) {
        return BASE_URL + relativeUrl;
    }

    private static void fetchGlobalIPWithResponseHandler(AsyncHttpResponseHandler handler){

        client.get(getAbsoluteUrl("ip"), handler);
    }

    public static void fetchCurrentASNWithResponseHandler(AsyncHttpResponseHandler handler) {
        final AsyncHttpResponseHandler finHandler = handler;
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
                            JSONObject postData = new JSONObject();
                            postData.put("ip", ip);
                            StringEntity entity = new StringEntity(postData.toString());
                            entity.setContentType("application/json");
                            client.post(null, getAbsoluteUrl("iptoasn"), entity, "application/json", finHandler);
                        }else {
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
            }

            @Override
            public void onFinish() {
                finHandler.onFinish();
            }
        });

    }

}
