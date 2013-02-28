package com.peer1.internetmap;

import android.content.Context;
import android.content.res.Configuration;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.widget.Toast;

/**
 * Contains various little helper methods shared between activities.
 *
 */
public class Helper {
    public static boolean isSmallScreen(Context context) {
        Configuration config = context.getResources().getConfiguration();
        if (config.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            //if the user forces a phone to landscape mode, the big-screen UI fits better.
            return false;
        }
        int screenSize = config.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK;
        return screenSize <= Configuration.SCREENLAYOUT_SIZE_NORMAL;
    }
    
    public static void showError(Context context, String message) {
        //TODO: I'm not sure if a dialog or a toast is most appropriate for errors.
        Toast.makeText(context, message, Toast.LENGTH_LONG).show();
    }
    
    public static boolean haveConnectivity(Context context){
        //check Internet status
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
        boolean isConnected = (activeNetwork == null) ? false : activeNetwork.isConnectedOrConnecting();
        if (!isConnected) {
            showError(context, context.getString(R.string.noInternet));
            return false;
        } else {
            return true;
        }
    }
}
