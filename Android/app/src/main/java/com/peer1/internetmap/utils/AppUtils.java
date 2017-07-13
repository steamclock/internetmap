package com.peer1.internetmap.utils;

import java.io.InputStream;

import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.widget.Toast;

import com.peer1.internetmap.R;

/**
 * Contains various little helper methods shared between activities.
 *
 */
public class AppUtils {
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

    public static byte[] readFileAsBytes(Context context, String filePath) throws java.io.IOException {
        InputStream input = context.getAssets().open(filePath);

        int size = input.available();
        byte[] buffer = new byte[size];
        input.read(buffer);
        input.close();

        return buffer;
    }
    public static int dpToPx(int dp) {
        return (int) (dp * Resources.getSystem().getDisplayMetrics().density);
    }

    public static int pxToDp(int px) {
        return (int) (px / Resources.getSystem().getDisplayMetrics().density);
    }

    public static float dpToPx(float dp) {
        return (dp * Resources.getSystem().getDisplayMetrics().density);
    }

    public static float pxToDp(float px) {
        return (px / Resources.getSystem().getDisplayMetrics().density);
    }
}
