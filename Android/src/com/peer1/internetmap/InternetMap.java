package com.peer1.internetmap;

import java.io.InputStream;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Point;
import android.os.Build;
import android.app.AlertDialog;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.view.*;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.PopupWindow;
import android.view.ViewGroup.LayoutParams;
import android.util.Log;

public class InternetMap extends Activity implements SurfaceHolder.Callback {

    private static String TAG = "InternetMap";

    private PopupWindow visualizationPopup;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);

        Log.i(TAG, "onCreate()");

        nativeOnCreate();

        setContentView(R.layout.main);
        SurfaceView surfaceView = (SurfaceView) findViewById(R.id.surfaceview);
        surfaceView.getHolder().addCallback(this);
    }

    public String readFileAsString(String filePath) throws java.io.IOException {
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

    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
        android.view.Display display = getWindowManager().getDefaultDisplay();
        
        int width, height;
        //getSize is only available from api 13
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR2) {
            Point size = new Point();
            display.getSize(size);
            width = size.x;
            height = size.y;
        } else {
            width = display.getWidth();
            height = display.getHeight();
        }

        Log.i(TAG, String.format("screen %d %d ", width, height, getResources().getDisplayMetrics().density));
        Log.i(TAG, String.format("surface %d %d %.2f", w, h, getResources().getDisplayMetrics().density));
        nativeSetSurface(holder.getSurface(), getResources().getDisplayMetrics().density);
    }

    public void surfaceCreated(SurfaceHolder holder) {
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        nativeSetSurface(null, 1.0f);
    }



    //UI stuff

    public void visualizationsButtonPressed(View view) {
        if (visualizationPopup == null) {

            LayoutInflater layoutInflater
                    = (LayoutInflater)getBaseContext()
                    .getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.visualizationview, null);
            visualizationPopup = new PopupWindow(popupView, LayoutParams.WRAP_CONTENT,
                    LayoutParams.WRAP_CONTENT);
            visualizationPopup.setBackgroundDrawable(new ColorDrawable(Color.argb(200, 0, 0, 0)));
            visualizationPopup.setOutsideTouchable(true);
            visualizationPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                @Override
                public void onDismiss() {
                    visualizationPopup = null;
                }
            });
            final ListView listView = (ListView)popupView.findViewById(R.id.visualizationList);
            String[] values = new String[] {"Network View", "Globe View"};
            final VisualizationArrayAdapter adapter = new VisualizationArrayAdapter(this, android.R.layout.simple_list_item_1, android.R.id.text1, values);
            listView.setAdapter(adapter);

            listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
                @Override
                public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {

                    Log.d("INT_MAP", "Tapped row " + position);
                    adapter.selectedRow = position;
                    listView.invalidateViews();
                }
            });


            visualizationPopup.showAsDropDown(findViewById(R.id.visualizationsButton));
        }
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
