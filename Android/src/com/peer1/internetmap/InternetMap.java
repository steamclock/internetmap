package com.peer1.internetmap;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Iterator;

import android.view.animation.AlphaAnimation;
import android.view.animation.AnimationUtils;
import android.widget.*;
import junit.framework.Assert;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.Point;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Handler;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.Gravity;
import android.view.ScaleGestureDetector;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.view.ViewTreeObserver;
import android.support.v4.view.GestureDetectorCompat;
import android.util.Log;
import com.peer1.internetmap.ASNRequest.ASNResponseHandler;
import net.hockeyapp.android.CrashManager;
import net.hockeyapp.android.UpdateManager;

public class InternetMap extends Activity implements SurfaceHolder.Callback {

    private static String TAG = "InternetMap";
    private final String APP_ID = "9a3f1d8d25e8728007a8abf2d420beb9"; //HockeyApp id
    private GestureDetectorCompat mGestureDetector;
    private ScaleGestureDetector mScaleDetector;
    private RotateGestureDetector mRotateDetector;
    
    private MapControllerWrapper mController;
    private Handler mHandler; //handles threadsafe messages

    private VisualizationPopupWindow mVisualizationPopup;
    private InfoPopup mInfoPopup;
    private SearchPopup mSearchPopup;
    private NodePopup mNodePopup;
    
    private int mUserNodeIndex = -1; //cache user's node from "you are here"
    private JSONObject mTimelineHistory; //history data for timeline
    private int mTimelineMinYear;
    public int mCurrentVisualization; //cached for the visualization popup
    private boolean mInTimelineMode; //true if we're showing the timeline
    private CallbackHandler mCameraResetHandler;
    private TimelinePopup mTimelinePopup;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);

        Log.i(TAG, "onCreate()");
        //check HockeyApp for updates (comment this out for release)
        UpdateManager.register(this, APP_ID);
        
        //try to get into the best orientation before initializing the backend
        forceOrientation();
        nativeOnCreate(isSmallScreen());

        setContentView(R.layout.main);
        final SurfaceView surfaceView = (SurfaceView) findViewById(R.id.surfaceview);
        surfaceView.getHolder().addCallback(this);

        mGestureDetector = new GestureDetectorCompat(this, new MyGestureListener());
        mScaleDetector = new ScaleGestureDetector(this, new ScaleListener());
        mRotateDetector = new RotateGestureDetector(this, new RotateListener());
        
        mController = new MapControllerWrapper();
        mHandler = new Handler();
        
        SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
        timelineBar.setOnSeekBarChangeListener(new TimelineListener());

        //fade out logo a bit after
        ImageView logo = (ImageView) findViewById(R.id.peerLogo);
        AlphaAnimation anim = new AlphaAnimation(1, 0.3f);
        anim.setDuration(1000);
        anim.setStartTime(AnimationUtils.currentAnimationTimeMillis()+4000);
        anim.setFillAfter(true);
        anim.setFillEnabled(true);
        logo.setAnimation(anim);
    }
    
    void onBackendLoaded() {
        //possibly show first-run slides
        final SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        if (prefs.getBoolean("firstrun", true)) {
            showHelp();
            prefs.edit().putBoolean("firstrun", false).commit();
        }
    }
    
    public void showHelp() {
        LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View popupView = layoutInflater.inflate(R.layout.help, null);
        HelpPopup popup = new HelpPopup(this, popupView);
        //show it
        View mainView = findViewById(R.id.mainLayout);
        Assert.assertNotNull(mainView);
        popup.setWidth(mainView.getWidth());
        popup.setHeight(mainView.getHeight());
        int gravity = Gravity.BOTTOM; //to avoid offset issues
        popup.showAtLocation(mainView, gravity, 0, 0);
    }
    
    public void forceOrientation() {
        Configuration config = getResources().getConfiguration();
        int screenSize = config.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK;
        Log.d(TAG, String.format("Size: %d", screenSize));
        int orientation = (screenSize <= Configuration.SCREENLAYOUT_SIZE_NORMAL) ? 
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT : ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
        setRequestedOrientation(orientation);
    }

    public byte[] readFileAsBytes(String filePath) throws java.io.IOException {
        Log.i(TAG, String.format("Reading %s", filePath));
        InputStream input = getAssets().open(filePath);

        int size = input.available();
        byte[] buffer = new byte[size];
        input.read(buffer);
        input.close();

        return buffer;
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        Log.i(TAG, "onRestart()");
        //force again in case the user was playing with an orientation app
        forceOrientation();
    }
    
    @Override
    protected void onResume() {
        super.onResume();
        Log.i(TAG, "onResume()");
        //check HockeyApp for crashes. comment this out for release
        CrashManager.register(this, APP_ID);
        nativeOnResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        Log.i(TAG, "onPause()");
        nativeOnPause();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.i(TAG, "onDestroy()");
        UpdateManager.unregister(); 
        nativeOnDestroy();
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
        
        //handle assorted gestures
        mScaleDetector.onTouchEvent(event);
        mRotateDetector.onTouchEvent(event);
        mGestureDetector.onTouchEvent(event);
        
        //ensure we clean up when the touch ends
        if (event.getAction() == MotionEvent.ACTION_CANCEL || event.getAction() == MotionEvent.ACTION_UP) {
            Log.d(TAG, "touch end");
            mController.setAllowIdleAnimation(true);
            mController.unhoverNode();
        }
        
        return super.onTouchEvent(event);
    }

    public void visualizationsButtonPressed(View view) {
        dismissPopups();

        //make the button change sooner, and don't let them toggle the button while we're loading
        final ToggleButton button = (ToggleButton)findViewById(R.id.visualizationsButton);
        button.setChecked(true);
        
        if (mVisualizationPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.visualizationview, null);
            mVisualizationPopup = new VisualizationPopupWindow(this, mController, popupView);
            mVisualizationPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mVisualizationPopup = null;
                    button.setChecked(false);
                }
            });
            mVisualizationPopup.showAsDropDown(findViewById(R.id.visualizationsButton));
        }
    }
    
    public void setVisualization(final int index) {
        //note: assuming all popups are gone because the visualization popup just finished.
        mCameraResetHandler = new CallbackHandler(){
            public void handle() {
                mCurrentVisualization = index;
                mController.setVisualization(index);
            }
        };
        mController.resetZoomAndRotationAnimated(isSmallScreen());
    }

    public void infoButtonPressed(View view) {
        dismissPopups();
        
        //make the button change sooner, and don't let them toggle the button while we're loading
        final ToggleButton button = (ToggleButton)findViewById(R.id.infoButton);
        button.setChecked(true);

        if (mInfoPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.visualizationview, null);
            mInfoPopup = new InfoPopup(this, mController, popupView);
            mInfoPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mInfoPopup = null;
                    button.setChecked(false);
                }
            });
            mInfoPopup.showAsDropDown(findViewById(R.id.infoButton));
        }
    }

    public void searchButtonPressed(View view) {
        dismissPopups();

        //make the button change sooner, and don't let them toggle the button while we're loading
        final ToggleButton button = (ToggleButton)findViewById(R.id.searchButton);
        button.setChecked(true);
        
        if (mSearchPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.searchview, null);
            mSearchPopup = new SearchPopup(this, mController, popupView);
            mSearchPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mSearchPopup = null;
                    button.setChecked(false);
                }
            });
            mSearchPopup.showAsDropDown(findViewById(R.id.searchButton));
        }
    }
    
    public void findHost(final String host) {
        Log.d(TAG, String.format("find host: %s", host));
        if (!haveConnectivity()) {
            return;
        }
        
        //TODO animate
        final ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
        final Button button = (Button) findViewById(R.id.searchButton);
        progress.setVisibility(View.VISIBLE);
        button.setVisibility(View.INVISIBLE);
        
        //dns lookup in the background
        new AsyncTask<Void, Void, String>() {
            @Override
            protected String doInBackground(Void... params) {
                String addrString;
                try {
                    InetAddress address = InetAddress.getByName(host);
                    addrString = address.getHostAddress();
                } catch (UnknownHostException e) {
                    addrString = "";
                }
                return addrString;
            }
            protected void onPostExecute(String addrString) {
                if (addrString.isEmpty()) {
                    showError(String.format(getString(R.string.invalidHost), host));
                    //stop animating
                    progress.setVisibility(View.INVISIBLE);
                    button.setVisibility(View.VISIBLE);
                } else {
                    Log.d(TAG, addrString);
                    ASNRequest.fetchASNForIP(addrString, new ASNResponseHandler() {
                    public void onStart() {
                        Log.d(TAG, "asnrequest2 start");
                        //nothing to do; already animating
                    }
                    public void onFinish() {
                        Log.d(TAG, "asnrequest2 finish");
                        //stop animating
                        progress.setVisibility(View.INVISIBLE);
                        button.setVisibility(View.VISIBLE);
                    }

                    public void onSuccess(JSONObject response) {
                        selectNodeByASN(response, false);
                    }
                
                    public void onFailure(Throwable e, String response) {
                        //tell the user
                        String message = getString(R.string.asnAssociationFail);
                        showError(message);
                        Log.d(TAG, message);
                    }
                });
                }
            }
        }.execute();
    }
    
    public void dismissSearchPopup(View unused) {
        mSearchPopup.dismiss();
    }

    public void youAreHereButtonPressed() {

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
                ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
                Button button = (Button) findViewById(R.id.searchButton);
                progress.setVisibility(View.VISIBLE);
                button.setVisibility(View.INVISIBLE);
            }
            public void onFinish() {
                Log.d(TAG, "asnrequest finish");
                //stop animating
                ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
                Button button = (Button) findViewById(R.id.searchButton);
                progress.setVisibility(View.INVISIBLE);
                button.setVisibility(View.VISIBLE);
            }

            public void onSuccess(JSONObject response) {
                   selectNodeByASN(response, true);
            }
        
            public void onFailure(Throwable e, String response) {
                //tell the user
                String message = getString(R.string.currentASNFail);
                showError(message);
                Log.d(TAG, message);
            }
        });
    }

    public void timelineButtonPressed(View view) {
        Log.d(TAG, "timeline");
        if (mInTimelineMode) {
            dismissPopups(); //leave timeline mode
        } else {
            dismissPopups();
            mController.resetZoomAndRotationAnimated(isSmallScreen());
            
            SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
            if (mTimelineHistory == null) {
                //load history data & init the timeline bounds
                try {
                    mTimelineHistory = new JSONObject(new String(readFileAsBytes("data/history.json")));
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
            timelineBar.requestLayout(); //hack to work around SurfaceView bug on some phones
            
            mInTimelineMode = true;
            //reset the node popup, the lazy way
            if (mNodePopup != null) mNodePopup.dismiss();
            //get the timeline popup up (even if the slider didn't change)
            createTimelinePopup();
            showTimelinePopup(timelineBar, timelineBar.getMax());
        }
    }
    
    public void dismissPopups() {
        if (mInTimelineMode) {
            SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
            timelineBar.setVisibility(View.INVISIBLE);
            resetViewAndSetTimeline(mTimelineMinYear + timelineBar.getMax());
            mInTimelineMode = false;
            ToggleButton button = (ToggleButton)findViewById(R.id.timelineButton);
            button.setChecked(false);
        }
        if (mNodePopup != null) {
            mNodePopup.dismiss();
        }
        //search and visualization popups dismiss themselves, we can ignore them here
    }
    
    void createTimelinePopup() {
        Assert.assertNull(mTimelinePopup);
        LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
        View popupView = layoutInflater.inflate(R.layout.timelinepopup, null);
        if (isSmallScreen()) {
            popupView.findViewById(R.id.arrow).setVisibility(View.GONE);
        }
        mTimelinePopup = new TimelinePopup(InternetMap.this, popupView);
        mTimelinePopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
            public void onDismiss() {
                mTimelinePopup = null;
            }
        });
    }
    
    void showTimelinePopup(SeekBar seekBar, int progress) {
        Assert.assertNotNull(mTimelinePopup);
        String year = Integer.toString(progress + mTimelineMinYear);
        mTimelinePopup.setData(year, mTimelineHistory.optString(year));
        Log.d(TAG, year);
        
        //update size/position
        int width, offset;
        boolean needsUpdate;
        if (isSmallScreen()) {
            width = LayoutParams.MATCH_PARENT;
            offset = 0;
            needsUpdate = false;
        } else {
            width = LayoutParams.WRAP_CONTENT; //mainView.getWidth() / 2;
            //calculate offset to line up with the timelineBar
            int barWidth = seekBar.getWidth();
            int maxProgress = seekBar.getMax();
            int popupWidth = mTimelinePopup.getMeasuredWidth();
            //FIXME something is going slightly wrong around here and I don't know why.
            //the location is accurate for 2000 and 2006, but ever so slightly off for other points.
            int progressXLocation = (int)(barWidth * (float)progress / maxProgress);
            int progressXCenter = progressXLocation + seekBar.getThumbOffset();
            offset = progressXCenter - popupWidth/2; //center
            //Log.d(TAG, String.format("bar: %d popup: %d thumb: %d location: %d offset: %d", barWidth, popupWidth, progressXLocation, progressXCenter, offset));
            needsUpdate = true;
        }
        if (!mTimelinePopup.isShowing()) {
            //Log.d(TAG, "first show");
            mTimelinePopup.setWindowLayoutMode(width, LayoutParams.WRAP_CONTENT);
            mTimelinePopup.showAsDropDown(seekBar, offset, 0);
        } else if (needsUpdate) {
            mTimelinePopup.update(seekBar, offset, 0, -1, -1);
        }
    }

    private class TimelineListener implements SeekBar.OnSeekBarChangeListener{
        
        public void onStartTrackingTouch(SeekBar seekBar) {
            if (mTimelinePopup == null) {
                createTimelinePopup();
            }
        }
        
        public void onProgressChanged(SeekBar seekBar, int progress,
                boolean fromUser) {
            if (mTimelinePopup == null) {
                //Log.d(TAG, "ignoring progresschange");
                return;
            }
            showTimelinePopup(seekBar, progress);
        }
        
        public void onStopTrackingTouch(SeekBar seekBar) {
            int year = mTimelineMinYear + seekBar.getProgress();
            resetViewAndSetTimeline(year);
        }
    }
    
    public void resetViewAndSetTimeline(final int year) {
        if (mNodePopup != null) {
            mNodePopup.dismiss();
        }

        //Assert.assertNotNull(mTimelinePopup);
        if (mTimelinePopup != null) {
            mTimelinePopup.showLoadingText();
        }
        
        mCameraResetHandler = new CallbackHandler(){
            public void handle() {
                mController.setTimelinePoint(year);
                if (mTimelinePopup != null) {
                    mTimelinePopup.dismiss();
                }
            }
        };
        mController.resetZoomAndRotationAnimated(isSmallScreen());
    }
    
    //for handling the camera reset callback
    private interface CallbackHandler {
        public void handle();
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
    
    public void selectNodeByASN(JSONObject response, boolean cacheIndex) {
        //expected response format: {"payload":"ASxxxx"}
        try {
            String asnWithAS = response.getString("payload");
            String asnString = asnWithAS.substring(2);
            Log.d(TAG, String.format("2asn: %s", asnString));
            //yay, an ASN! turn it into a node so we can target it.
            NodeWrapper node = mController.nodeByAsn(asnString);
            if (node != null) {
                if (cacheIndex) {
                    mUserNodeIndex = node.index;
                }
                mController.updateTargetForIndex(node.index);
            } else {
                showError(getString(R.string.asnAssociationFail));
            }
        } catch (Exception e) {
            Log.d(TAG, String.format("can't parse response: %s", response.toString()));
            showError(getString(R.string.asnAssociationFail));
        }
    }
    
    public boolean isSmallScreen() {
        Configuration config = getResources().getConfiguration();
        if (config.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            //if the user forces a phone to landscape mode, the big-screen UI fits better.
            return false;
        }
        int screenSize = config.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK;
        Log.d(TAG, String.format("size: %d", screenSize));
        return screenSize <= Configuration.SCREENLAYOUT_SIZE_NORMAL;
    }

    //called from c++ via threadsafeShowNodePopup
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
                View popupView;
                if (mInTimelineMode) {
                    popupView = layoutInflater.inflate(R.layout.nodetimelineview, null);
                } else {
                    popupView = layoutInflater.inflate(R.layout.nodeview, null);
                    if (isSmallScreen()) {
                        popupView.findViewById(R.id.leftArrow).setVisibility(View.GONE);
                    }
                }
                mNodePopup = new NodePopup(this, popupView, mInTimelineMode);
                mNodePopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                    public void onDismiss() {
                        mNodePopup = null;
                        mController.deselectCurrentNode();
                        mController.resetZoomAndRotationAnimated(isSmallScreen());
                    }
                });
            }
            boolean isUserNode = (node.index == mUserNodeIndex);
            mNodePopup.setNode(node, isUserNode);
            //update size/position
            View mainView = findViewById(R.id.surfaceview);
            int gravity, width;
            //note: PopupWindow appears to ignore gravity width/height hints
            //and most of its size setters only take absolute numbers; setWindowLayoutMode is the exception
            //but, setWindowLayoutMode doesn't properly handle absolute numbers either, so we may have to call *both*.
            if (mInTimelineMode) {
                gravity = Gravity.CENTER; //FIXME it should be a bit above center but that's hard
                width = mainView.getWidth() / 2;
            } else if (isSmallScreen()) {
                gravity = Gravity.BOTTOM;
                width = LayoutParams.MATCH_PARENT;
            } else {
                gravity = Gravity.CENTER_VERTICAL | Gravity.RIGHT;
                width = mainView.getWidth() / 2;
            }
            mNodePopup.setWindowLayoutMode(width, LayoutParams.WRAP_CONTENT);
            mNodePopup.setWidth(width);
            mNodePopup.setHeight(mNodePopup.getMeasuredHeight()); //work around weird bugs
            mNodePopup.showAtLocation(mainView, gravity, 0, 0);
            //Log.d(TAG, String.format("showing : %d", mNodePopup.getHeight()));
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
                    showError(getString(R.string.tracerouteStartIPFail));
                }
            }
        
            public void onFailure(Throwable e, String response) {
                String message = getString(R.string.tracerouteStartIPFail);
                showError(message);
                Log.d(TAG, message);
            }
        });        
        
    }

    //native wrappers
    public native void nativeOnCreate(boolean smallScreen);
    public native void nativeOnResume();
    public native void nativeOnPause();
    public native void nativeOnDestroy();
    public native void nativeSetSurface(Surface surface, float density);
    
    //threadsafe callbacks for c++
    public void threadsafeShowNodePopup() {
        mHandler.post(new Runnable() {
            public void run() {
                showNodePopup();
            }
        });
    }
    public void threadsafeCameraResetCallback() {
        mHandler.post(new Runnable() {
            public void run() {
                if (mCameraResetHandler != null) {
                    mCameraResetHandler.handle();
                    mCameraResetHandler = null;
                }
            }
        });
    }
    public void threadsafeLoadFinishedCallback() {
        mHandler.post(new Runnable() {
            public void run() {
                onBackendLoaded();
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
            float x = event.getX();
            float y = event.getY();
            SurfaceView surfaceView = (SurfaceView) findViewById(R.id.surfaceview);
            int location[] = new int[2];
            surfaceView.getLocationOnScreen(location);
            int top = location[1];
            int left = location[0];
            //Log.d(TAG, String.format("onDown %f %f %d %d", x, y, top, left));
            mController.setAllowIdleAnimation(false);
            mController.handleTouchDownAtPoint(x - left, y - top);
            return true;
        }

        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX,
                float distanceY) {
            //Log.d(TAG, String.format("onScroll: x %f y %f", distanceX, distanceY));
            mController.rotateRadiansXY(distance2radians(distanceX), distance2radians(distanceY));
            return true;
        }
        
        @Override
        public boolean onFling(MotionEvent event1, MotionEvent event2, 
                float velocityX, float velocityY) {
            //Log.d(TAG, String.format("onFling: vx %f vy %f", velocityX, velocityY));
            mController.startMomentumPanWithVelocity(velocityAdjust(velocityX), velocityAdjust(velocityY));
            return true;
        }

        @Override
        //note: if double tap is used this should probably s/Up/Confirmed
        public boolean onSingleTapUp(MotionEvent e) {
            Log.d(TAG, "tap!");
            boolean selected = mController.selectHoveredNode();
            if (!selected && mNodePopup != null) {
                mNodePopup.dismiss();
            }
            return true;
        }
    }

    //zoom gesture
    private class ScaleListener extends ScaleGestureDetector.SimpleOnScaleGestureListener {
        @Override
        public boolean onScale(ScaleGestureDetector detector) {
            float scale = detector.getScaleFactor() - 1;
            //Log.d(TAG, String.format("scale: %f", scale));
            mController.zoomByScale(scale);
            return true;
        }

        @Override
        public void onScaleEnd(ScaleGestureDetector detector) {
            float scale = detector.getScaleFactor() - 1;
            //Log.d(TAG, String.format("scaleEnd: %f", scale));
            mController.startMomentumZoomWithVelocity(scale * 50);
        }
    }

    //2-finger rotate gesture
    private class RotateListener extends RotateGestureDetector.SimpleOnRotateGestureListener {
        @Override
        public boolean onRotate(RotateGestureDetector detector) {
            float rotate = detector.getRotateFactor();
            //Log.d(TAG, String.format("!!rotate: %f", rotate));
            mController.rotateRadiansZ(-rotate);
            return true;
        }

        @Override
        public void onRotateEnd(RotateGestureDetector detector) {
            float velocity = detector.getRotateFactor(); //FIXME not actually velocity. always seems to be 0
            //Log.d(TAG, String.format("!!!!rotateEnd: %f", velocity));
            mController.startMomentumRotationWithVelocity(velocity * 50);
        }
    }
    
}
