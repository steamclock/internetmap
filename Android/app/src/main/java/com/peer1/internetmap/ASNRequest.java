package com.peer1.internetmap;

import com.loopj.android.http.AsyncHttpClient;

import org.json.JSONObject;

/**
 * NOTE, no longer used, we have moved to using Retrofit and OKHttp via the CommonClient class.

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

    private static final String BASE_URL = "http://asnl.peer1.com/v1/";

    private static final AsyncHttpClient client = new AsyncHttpClient();

    private static String getAbsoluteUrl(String relativeUrl) {
        return BASE_URL + relativeUrl;
        //return BASE_URL + "invalid";
    }

//    private static void fetchGlobalIPWithResponseHandler(AsyncHttpResponseHandler handler) {
//
//        client.get(getAbsoluteUrl("ip"), handler);
//    }
    
//    public static void fetchASNForIP(String ip, final ASNResponseHandler finHandler) {
//        //calls from outside can't have already started, and probably want errors caught.
//        try {
//            fetchASNForIP(ip, false, finHandler);
//        } catch (Exception e) {
//            finHandler.onFailure(new Throwable(e.getMessage()), null);
//        }
//    }
    
//    private static void fetchASNForIP(String ip, final boolean alreadyStarted, final ASNResponseHandler finHandler) throws JSONException, UnsupportedEncodingException {
//        JSONObject postData = new JSONObject();
//        postData.put("ip", ip);
//        StringEntity entity = new StringEntity(postData.toString());
//        entity.setContentType("application/json");
//        client.post(null, getAbsoluteUrl("iptoasn"), entity, "application/json", new AsyncHttpResponseHandler(){
//            @Override
//            public void onStart(){
//                //only trigger start if some other part of ASNRequest didn't already do it.
//                if (!alreadyStarted) {
//                    finHandler.onStart();
//                }
//            }
//            @Override
//            public void onSuccess(String response) {
//                try {
//                    finHandler.onSuccess(new JSONObject(response));
//                } catch (JSONException e) {
//                    onFailure(new Throwable(e.getMessage()), null);
//                }
//            }
//            @Override
//            public void onFailure(Throwable error, String content) {
//                finHandler.onFailure(error, content);
//            }
//            @Override
//            public void onFinish() {
//                finHandler.onFinish();
//            }
//        });
//    }

//    public static void fetchIPsForASN(String asn, final ASNResponseHandler finHandler) throws JSONException, UnsupportedEncodingException {
//        JSONObject postData = new JSONObject();
//        postData.put("asn", asn);
//        StringEntity entity = null;
//        try{
//        	entity = new StringEntity(postData.toString());
//        } catch (UnsupportedEncodingException error) {
//        	System.err.println ( error ) ;
//        	// Do we want to notify the user if we have some kind of encoding exception?
//        }
//        entity.setContentType("application/json");
//        client.post(null, getAbsoluteUrl("asntoips"), entity, "application/json", new AsyncHttpResponseHandler(){
//            @Override
//            public void onStart(){
//                finHandler.onStart();
//            }
//            @Override
//            public void onSuccess(String response) {
//                try {
//                    finHandler.onSuccess(new JSONObject(response));
//                } catch (JSONException e) {
//                    onFailure(new Throwable(e.getMessage()), null);
//                }
//            }
//            @Override
//            public void onFailure(Throwable error, String content) {
//                finHandler.onFailure(error, content);
//            }
//            @Override
//            public void onFinish() {
//                finHandler.onFinish();
//            }
//        });
//    }
    
//    public static void fetchCurrentASNWithResponseHandler(final ASNResponseHandler finHandler) {
//
//        CommonClient.getInstance().getGlobalIP().enqueue(new CommonCallback<GlobalIP>() {
//            @Override
//            public void onRequestResponse(Call<GlobalIP> call, Response<GlobalIP> response) {
//                GlobalIP result = response.body();
//
//                if (result.ip == null || result.ip.isEmpty()) {
//                    // ERROR
//                } else {
//                    //fetchASNForIP(ip, true, finHandler);
//                    Toast.makeText()
//                }
//
//
//                if (result != null && !result.isEmpty()) {
//                    try {
//                        JSONObject jsonObject = new JSONObject(result);
//                        String ip = jsonObject.getString("payload");
//
//                        if (ip != null && !ip.isEmpty()) {
//                            fetchASNForIP(ip, true, finHandler);
//                        } else {
//                            finHandler.onFailure(new Throwable(""), null);
//                        }
//                    } catch (Exception e) {
//                        finHandler.onFailure(e, e.getMessage());
//                    }
//
//                } else {
//                    finHandler.onFailure(new Throwable(""), null);
//                }
//            }
//
//            @Override
//            public void onRequestFailure(Call<GlobalIP> call, Throwable t) {
//
//            }
//        });
//    }

//    public static void fetchCurrentASNWithResponseHandlerOld(final ASNResponseHandler finHandler) {
//        fetchGlobalIPWithResponseHandler(new AsyncHttpResponseHandler() {
//
//            @Override
//            public void onStart(){
//                finHandler.onStart();
//            }
//
//            @Override
//            public void onSuccess(String response) {
//                String errorString = "Couldn't resolve current global IP.";
//                if (response != null && !response.isEmpty()) {
//                    try {
//                        JSONObject jsonObject = new JSONObject(response);
//                        String ip = jsonObject.getString("payload");
//                        if (ip != null && !ip.isEmpty()) {
//                            fetchASNForIP(ip, true, finHandler);
//                        } else {
//                            onFailure(new Throwable(errorString), null);
//                        }
//                    } catch (Exception e) {
//                        onFailure(new Throwable(e.getMessage()), null);
//                    }
//
//                } else {
//                    onFailure(new Throwable(errorString), null);
//                }
//            }
//
//            @Override
//            public void onFailure(Throwable error, String content) {
//                finHandler.onFailure(error, content);
//                //if request #1 failed, then request #2 never started, so we're responsible for cleanup.
//                finHandler.onFinish();
//            }
//        });
//
//    }

}
