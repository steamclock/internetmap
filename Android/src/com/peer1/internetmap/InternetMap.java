package com.peer1.internetmap;

import java.io.InputStream;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Point;
import android.os.Build;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.PopupWindow;
import android.view.ScaleGestureDetector;
import android.view.ViewGroup.LayoutParams;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.SurfaceHolder;
import android.view.View;
import android.support.v4.view.GestureDetectorCompat;
import android.util.Log;

public class InternetMap extends Activity implements SurfaceHolder.Callback {

    private static String TAG = "InternetMap";
    private GestureDetectorCompat mGestureDetector;
    private ScaleGestureDetector mScaleDetector;
    private RotateGestureDetector mRotateDetector;

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
        
        mGestureDetector = new GestureDetectorCompat(this, new MyGestureListener());
        mScaleDetector = new ScaleGestureDetector(this, new ScaleListener());
        mRotateDetector = new RotateGestureDetector(this, new RotateListener());
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

    @Override
    public boolean onTouchEvent(MotionEvent event){
        mScaleDetector.onTouchEvent(event);
        mRotateDetector.onTouchEvent(event);
        mGestureDetector.onTouchEvent(event);
        return super.onTouchEvent(event);
    }

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
                public void onDismiss() {
                    visualizationPopup = null;
                }
            });
            final ListView listView = (ListView)popupView.findViewById(R.id.visualizationList);
            String[] values = new String[] {"Network View", "Globe View"};
            final VisualizationArrayAdapter adapter = new VisualizationArrayAdapter(this, android.R.layout.simple_list_item_1, android.R.id.text1, values);
            listView.setAdapter(adapter);

            listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
                public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {

                    Log.d("INT_MAP", "Tapped row " + position);
                    adapter.selectedRow = position;
                    listView.invalidateViews();
                }
            });


            visualizationPopup.showAsDropDown(findViewById(R.id.visualizationsButton));
        }
    }


    //native wrappers
    public native void nativeOnCreate();

    public native void nativeOnResume();

    public native void nativeOnPause();

    public native void nativeOnStop();

    public native void nativeSetSurface(Surface surface, float density);
    
    public native void nativeRotateRadiansXY(float radX, float radY);
    public native void nativeStartMomentumPanWithVelocity(float vX, float vY);
    public native void nativeHandleTouchDownAtPoint(float x, float y);
    public native void nativeZoomByScale(float scale);
    public native void nativeStartMomentumZoomWithVelocity(float velocity);
    public native void nativeRotateRadiansZ(float radians);
    public native void nativeStartMomentumRotationWithVelocity(float velocity);
    public native boolean nativeSelectHoveredNode();

    static {
        System.loadLibrary("internetmaprenderer");
    }

    //simple one-finger gestures (eg. pan)
    class MyGestureListener extends GestureDetector.SimpleOnGestureListener {
        private float distance2radians(float distance) {
            return -0.01f * distance;
        }
        private float velocityAdjust(float velocity) {
            return 0.002f * velocity;
        }

        @Override
        public boolean onDown(MotionEvent event) { 
            Log.d(TAG,"onDown");
            nativeHandleTouchDownAtPoint(event.getX(), event.getY());
            return true;
        }

        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX,
                float distanceY) {
            Log.d(TAG, String.format("onScroll: x %f y %f", distanceX, distanceY));
            nativeRotateRadiansXY(distance2radians(distanceX), distance2radians(distanceY));
            return true;
        }
        
        @Override
        public boolean onFling(MotionEvent event1, MotionEvent event2, 
                float velocityX, float velocityY) {
            Log.d(TAG, String.format("onFling: vx %f vy %f", velocityX, velocityY));
            nativeStartMomentumPanWithVelocity(velocityAdjust(velocityX), velocityAdjust(velocityY));
            return true;
        }

        @Override
        //note: if double tap is used this should probably s/Up/Confirmed
        public boolean onSingleTapUp(MotionEvent e) {
            Log.d(TAG, "tap!");
            nativeSelectHoveredNode();
            //TODO: iOS does some deselect stuff if that call failed.
            //but, I think maybe that should just happen inside the controller automatically.
            return true;
        }
    }

    //zoom gesture
    private class ScaleListener extends ScaleGestureDetector.SimpleOnScaleGestureListener {
        @Override
        public boolean onScale(ScaleGestureDetector detector) {
            float scale = detector.getScaleFactor() - 1;
            Log.d(TAG, String.format("scale: %f", scale));
            nativeZoomByScale(scale);
            return true;
        }

        @Override
        public void onScaleEnd(ScaleGestureDetector detector) {
            float scale = detector.getScaleFactor() - 1;
            Log.d(TAG, String.format("scaleEnd: %f", scale));
            nativeStartMomentumZoomWithVelocity(scale*50);
        }
    }

    //2-finger rotate gesture
    private class RotateListener extends RotateGestureDetector.SimpleOnRotateGestureListener {
        @Override
        public boolean onRotate(RotateGestureDetector detector) {
            float rotate = detector.getRotateFactor();
            Log.d(TAG, String.format("!!rotate: %f", rotate));
            nativeRotateRadiansZ(-rotate);
            return true;
        }

        @Override
        public void onRotateEnd(RotateGestureDetector detector) {
            float velocity = detector.getRotateFactor(); //FIXME not actually velocity. always seems to be 0
            Log.d(TAG, String.format("!!!!rotateEnd: %f", velocity));
            nativeStartMomentumRotationWithVelocity(velocity*50);
        }
    }
    
}
