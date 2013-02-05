package com.peer1.internetmap;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.Iterator;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Point;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Bundle;
import android.widget.Button;
import android.widget.PopupWindow;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.Toast;
import android.view.ScaleGestureDetector;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.SurfaceHolder;
import android.view.View;
import android.support.v4.view.GestureDetectorCompat;
import android.util.Log;
import com.peer1.internetmap.ASNRequest.ASNResponseHandler;

public class InternetMap extends Activity implements SurfaceHolder.Callback {

    private static String TAG = "InternetMap";
    private GestureDetectorCompat mGestureDetector;
    private ScaleGestureDetector mScaleDetector;
    private RotateGestureDetector mRotateDetector;
    
    private MapControllerWrapper mController;
    private Handler mHandler; //handles threadsafe messages

    private VisualizationPopupWindow mVisualizationPopup;
    private SearchPopup mSearchPopup;
    private NodePopup mNodePopup;
    
    private int mUserNodeIndex = -1; //cache user's node from "you are here"
    private JSONObject mTimelineHistory; //history data for timeline
    private int mTimelineMinYear;

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
        
        mController = new MapControllerWrapper();
        mHandler = new Handler();
        
        SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
        timelineBar.setOnSeekBarChangeListener(new TimelineListener());
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
        dismissTimeline();

        if (mVisualizationPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.visualizationview, null);
            mVisualizationPopup = new VisualizationPopupWindow(this, popupView);
            mVisualizationPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mVisualizationPopup = null;
                }
            });
            mVisualizationPopup.showAsDropDown(findViewById(R.id.visualizationsButton));
        }
    }

    public void searchButtonPressed(View view) {
        dismissTimeline();

        if (mSearchPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.searchview, null);
            mSearchPopup = new SearchPopup(this, mController, popupView);
            mSearchPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mSearchPopup = null;
                }
            });
            mSearchPopup.showAsDropDown(findViewById(R.id.searchButton));
        }
    }
    
    public void findHost(String host) {
        Log.d(TAG, String.format("find host: %s", host));
        if (!haveConnectivity()) {
            return;
        }
        
        //TODO animate
        //TODO addressesForHost.
        String address = "";
        if (address.isEmpty()) {
            //TODO stop spinning
            showError(String.format(getString(R.string.invalidHost), host));
        } else {
            //TODO fetchForAddresses
        }
    }
    
    public void dismissSearchPopup(View unused) {
        mSearchPopup.dismiss();
    }

    public void youAreHereButtonPressed(View view) {
        dismissTimeline();

        //check internet status
        boolean isConnected = haveConnectivity();
        
        if (!isConnected) {
            return;
        }

        //do an ASN request to get the user's ASN
        ASNRequest.fetchCurrentASNWithResponseHandler(new ASNResponseHandler() {
            public void onStart() {
                Log.d(TAG, "asnrequest start");
                //animate
                ProgressBar progress = (ProgressBar) findViewById(R.id.youAreHereProgressBar);
                Button button = (Button) findViewById(R.id.youAreHereButton);
                progress.setVisibility(View.VISIBLE);
                button.setVisibility(View.INVISIBLE);
            }
            public void onFinish() {
                Log.d(TAG, "asnrequest finish");
                //stop animating
                ProgressBar progress = (ProgressBar) findViewById(R.id.youAreHereProgressBar);
                Button button = (Button) findViewById(R.id.youAreHereButton);
                progress.setVisibility(View.INVISIBLE);
                button.setVisibility(View.VISIBLE);
            }

            public void onSuccess(JSONObject response) {
                //expected response format: {"payload":"ASxxxx"}
                try {
                    String asnWithAS = response.getString("payload");
                    String asnString = asnWithAS.substring(2);
                    Log.d(TAG, String.format("asn: %s", asnString));
                    //yay, an ASN! turn it into a node so we can target it.
                    NodeWrapper node = mController.nodeByAsn(asnString);
                    if (node != null) {
                        mUserNodeIndex = node.index;
                        selectNode(node);
                    } else {
                        showError(String.format(getString(R.string.asnNullNode), asnString));
                    }
                } catch (Exception e) {
                    Log.d(TAG, String.format("can't parse response: %s", response.toString()));
                    showError(getString(R.string.asnBadResponse));
                }
            }
        
            public void onFailure(Throwable e, String response) {
                //tell the user
                //FIXME: outputting the raw error response is bad. how can we make it userfriendly?
                String message = String.format(getString(R.string.asnfail), response);
                showError(message);
                Log.d(TAG, message);
            }
        });
    }

    public void timelineButtonPressed(View view) {
        Log.d(TAG, "timeline");
        SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
        if (timelineBar.getVisibility() == View.VISIBLE) {
            dismissTimeline();
        } else {
            if (mTimelineHistory == null) {
                //load history data & init the timeline bounds
                try {
                    mTimelineHistory = new JSONObject(readFileAsString("data/history.json"));
                } catch (JSONException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                } catch (IOException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
                
                //get range
                String minYear = "9999";
                String maxYear = "0";
                Iterator<?> it = mTimelineHistory.keys();
                while(it.hasNext()){
                    //note: even though years are numbers, since all the ones we use are 2xxx, a string comparison is safe.
                    String year = (String)it.next();
                    if (year.compareTo(minYear) < 0) {
                        minYear = year;
                    }
                    if (year.compareTo(maxYear) > 0) {
                        maxYear = year;
                    }
                }
                Log.d(TAG, String.format("year span: %s to %s", minYear, maxYear));
                
                int min = Integer.parseInt(minYear);
                int max = Integer.parseInt(maxYear);
                int range = max - min;
                timelineBar.setMax(range);
                mTimelineMinYear = min;
            }
            timelineBar.setProgress(timelineBar.getMax());
            timelineBar.setVisibility(View.VISIBLE);
            //TODO: change node popup mode
        }
    }
    
    public void dismissTimeline() {
        SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
        if (timelineBar.getVisibility() == View.VISIBLE) {
            timelineBar.setVisibility(View.GONE);
            mController.setTimelinePoint(mTimelineMinYear + timelineBar.getMax());
            //TODO: change node popup mode
        }
    }

    private class TimelineListener implements SeekBar.OnSeekBarChangeListener{
        private TimelinePopup mTimelinePopup;
        
        public void onStartTrackingTouch(SeekBar seekBar) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.timelinepopup, null);
            mTimelinePopup = new TimelinePopup(InternetMap.this, popupView);
            mTimelinePopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mNodePopup = null;
                }
            });
        }
        
        public void onProgressChanged(SeekBar seekBar, int progress,
                boolean fromUser) {
            if (mTimelinePopup == null) {
                //Log.d(TAG, "ignoring progresschange");
                return;
            }
            String year = Integer.toString(progress + mTimelineMinYear);
            mTimelinePopup.setData(year, mTimelineHistory.optString(year));
            mTimelinePopup.showAsDropDown(findViewById(R.id.timelineSeekBar)); //FIXME x offset?
        }
        
        public void onStopTrackingTouch(SeekBar seekBar) {
            int year = mTimelineMinYear + seekBar.getProgress();
            mController.setTimelinePoint(year);
            mTimelinePopup.dismiss();
        }
    }
    
    public boolean haveConnectivity(){
        //check Internet status
        ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
        boolean isConnected = (activeNetwork == null) ? false : activeNetwork.isConnectedOrConnecting();
        if (!isConnected) {
            showError(getString(R.string.noInternet));
            return false;
        } else {
        	return true;
        }
    }
    
    public void showError(String message) {
        //TODO: I'm not sure if a dialog or a toast is most appropriate for errors.
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
    }
    
    public void selectNode(NodeWrapper node) {
        mController.updateTargetForIndex(node.index);
    }

    //called from c++
    public void showNodePopup() {
        Log.d(TAG, "showNodePopup");
        //get the current node
        int index = mController.targetNodeIndex();
        Log.d(TAG, String.format("node at index %d", index));
        NodeWrapper node = mController.nodeAtIndex(index);
        if (node == null) {
            Log.d(TAG, "is null");
            if (mNodePopup != null) {
                mNodePopup.dismiss();
            }
        } else {
            //node is ok; show the popup
            Log.d(TAG, String.format("has index %d and asn %s", node.index, node.asn));
            if (mNodePopup == null) {
                LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
                View popupView = layoutInflater.inflate(R.layout.nodeview, null);
                mNodePopup = new NodePopup(this, popupView);
                mNodePopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                    public void onDismiss() {
                        mNodePopup = null;
                    }
                });
            }
            boolean isUserNode = (node.index == mUserNodeIndex);
            mNodePopup.setNode(node, isUserNode);
            mNodePopup.showAsDropDown(findViewById(R.id.visualizationsButton)); //FIXME show by node
        }
    }
    
    //callbacks from the nodePopup UI
    public void dismissNodePopup(View unused) {
        mNodePopup.dismiss();
    }
    
    public void runTraceroute(View unused) throws JSONException, UnsupportedEncodingException{
        Log.d(TAG, "TODO: traceroute");
      //check internet status
        boolean isConnected = haveConnectivity();
        
        if (!isConnected) {
            return;
        }
        String asn = "AS15169";
        ASNRequest.fetchIPsForASN(asn, new ASNResponseHandler() {
            public void onStart() {

            }
            public void onFinish() {

            }

            public void onSuccess(JSONObject response) {
                try {
                	//Try and get legit payload here
                    Log.d(TAG, String.format("payload: %s", response));
                } catch (Exception e) {
                    Log.d(TAG, String.format("Can't parse response: %s", response.toString()));
                    showError(getString(R.string.asnBadResponse));
                }
            }
        
            public void onFailure(Throwable e, String response) {
                String message = String.format(getString(R.string.asnfail), response);
                showError(message);
                Log.d(TAG, message);
            }
        });        
        
    }

    //native wrappers
    public native void nativeOnCreate();
    public native void nativeOnResume();
    public native void nativeOnPause();
    public native void nativeOnStop();
    public native void nativeSetSurface(Surface surface, float density);
    
    //threadsafe callbacks for c++
    public void threadsafeShowNodePopup() {
        mHandler.post(new Runnable() {
            public void run() {
                showNodePopup();
            }
        });
    }
    

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
            Log.d(TAG, "onDown");
            mController.handleTouchDownAtPoint(event.getX(), event.getY());
            return true;
        }

        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX,
                float distanceY) {
            Log.d(TAG, String.format("onScroll: x %f y %f", distanceX, distanceY));
            mController.rotateRadiansXY(distance2radians(distanceX), distance2radians(distanceY));
            return true;
        }
        
        @Override
        public boolean onFling(MotionEvent event1, MotionEvent event2, 
                float velocityX, float velocityY) {
            Log.d(TAG, String.format("onFling: vx %f vy %f", velocityX, velocityY));
            mController.startMomentumPanWithVelocity(velocityAdjust(velocityX), velocityAdjust(velocityY));
            return true;
        }

        @Override
        //note: if double tap is used this should probably s/Up/Confirmed
        public boolean onSingleTapUp(MotionEvent e) {
            Log.d(TAG, "tap!");
            mController.selectHoveredNode();
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
            mController.zoomByScale(scale);
            return true;
        }

        @Override
        public void onScaleEnd(ScaleGestureDetector detector) {
            float scale = detector.getScaleFactor() - 1;
            Log.d(TAG, String.format("scaleEnd: %f", scale));
            mController.startMomentumZoomWithVelocity(scale * 50);
        }
    }

    //2-finger rotate gesture
    private class RotateListener extends RotateGestureDetector.SimpleOnRotateGestureListener {
        @Override
        public boolean onRotate(RotateGestureDetector detector) {
            float rotate = detector.getRotateFactor();
            Log.d(TAG, String.format("!!rotate: %f", rotate));
            mController.rotateRadiansZ(-rotate);
            return true;
        }

        @Override
        public void onRotateEnd(RotateGestureDetector detector) {
            float velocity = detector.getRotateFactor(); //FIXME not actually velocity. always seems to be 0
            Log.d(TAG, String.format("!!!!rotateEnd: %f", velocity));
            mController.startMomentumRotationWithVelocity(velocity * 50);
        }
    }
    
}
