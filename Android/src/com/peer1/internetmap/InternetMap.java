
package com.peer1.internetmap;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

import android.app.Activity;
import android.graphics.Point;
import android.os.Bundle;
import android.widget.Toast;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.View.OnClickListener;
import android.util.Log;

public class InternetMap extends Activity implements SurfaceHolder.Callback
{

    private static String TAG = "InternetMap";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.i(TAG, "onCreate()");

        nativeOnCreate();
        
        setContentView(R.layout.main);
        SurfaceView surfaceView = (SurfaceView)findViewById(R.id.surfaceview);
        surfaceView.getHolder().addCallback(this);
        surfaceView.setOnClickListener(new OnClickListener() {
                public void onClick(View view) {
                    Toast toast = Toast.makeText(InternetMap.this,
                                                 "Test tap overlay",
                                                 Toast.LENGTH_LONG);
                    toast.show();
                }});
    }

    public String readFileAsString(String filePath) throws java.io.IOException
    {
    	Log.i(TAG, String.format("Reading %s", filePath));
    	InputStream input = getAssets().open(filePath);

        int size = input.available();
        byte[] buffer = new byte[size];
        input.read(buffer);
        input.close();

        // byte buffer into a string
        return new String(buffer);
    }
    
    @Override
    protected void onResume() {
        super.onResume();
        Log.i(TAG, "onResume()");
        nativeOnResume();
    }
    
    @Override
    protected void onPause() {
        super.onPause();
        Log.i(TAG, "onPause()");
        nativeOnPause();
    }

    @Override
    protected void onStop() {
        super.onDestroy();
        Log.i(TAG, "onStop()");
        nativeOnStop();
    }

    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
    	android.view.Display display = getWindowManager().getDefaultDisplay();
    	Point size = new Point();
    	display.getSize(size);
    	int width = size.x;
    	int height = size.y;
    	
    	Log.i(TAG, String.format("screen %d %d ", width, height, getResources().getDisplayMetrics().density));
    	Log.i(TAG, String.format("surface %d %d %.2f", w, h, getResources().getDisplayMetrics().density));
        nativeSetSurface(holder.getSurface(), getResources().getDisplayMetrics().density);
    }

    public void surfaceCreated(SurfaceHolder holder) {
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        nativeSetSurface(null, 1.0f);
    }


    public native void nativeOnCreate();
    public native void nativeOnResume();
    public native void nativeOnPause();
    public native void nativeOnStop();
    public native void nativeSetSurface(Surface surface, float density);

    static {
        System.loadLibrary("internetmaprenderer");
    }

}
