package com.peer1.internetmap;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;

import android.app.Activity;
import android.content.Context;
import android.support.v4.content.ContextCompat;
import android.view.animation.AlphaAnimation;
import android.view.animation.AnimationUtils;
import android.widget.*;
import junit.framework.Assert;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.Point;
import android.graphics.drawable.Drawable;
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
import android.support.v4.view.GestureDetectorCompat;
import android.util.Log;

import com.peer1.internetmap.SearchPopup.SearchNode;
import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.network.common.CommonCallback;
import com.peer1.internetmap.network.common.CommonClient;

import net.hockeyapp.android.CrashManager;
import net.hockeyapp.android.UpdateManager;

import retrofit2.Call;
import retrofit2.Response;
import uk.co.chrisjenx.calligraphy.CalligraphyContextWrapper;

public class InternetMap extends BaseActivity implements SurfaceHolder.Callback {

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
    private ArrayList<String> mTimelineYears; //sorted year mapping
    private int mDefaultYearIndex; //index of the default year mTimelineYears
    public int mCurrentVisualization; //cached for the visualization popup
    private boolean mInTimelineMode; //true if we're showing the timeline
    private CallbackHandler mCameraResetHandler;
    private TimelinePopup mTimelinePopup;
    public ArrayList<SearchNode> mAllSearchNodes; //cache of nodes for search
    public boolean mDoneLoading;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);

        Log.i(TAG, "onCreate()");
        //check HockeyApp for updates (comment this out for release)
        //UpdateManager.register(this, APP_ID);
        
        //try to get into the best orientation before initializing the backend
        forceOrientation();
        mDoneLoading = nativeOnCreate(isSmallScreen());
        //no real create -> no pending callback. we'll check mDoneLoading later to compensate.

        setContentView(R.layout.main);
        final SurfaceView surfaceView = (SurfaceView) findViewById(R.id.surfaceview);
        surfaceView.getHolder().addCallback(this);

        //init a bunch of pointers
        mGestureDetector = new GestureDetectorCompat(this, new MyGestureListener());
        mScaleDetector = new ScaleGestureDetector(this, new ScaleListener());
        mRotateDetector = new RotateGestureDetector(this, new RotateListener());
        mController = new MapControllerWrapper();
        mHandler = new Handler();

        SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
        timelineBar.setOnSeekBarChangeListener(new TimelineListener());

        findViewById(R.id.timelineButton).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                timelineButtonPressed(v);
            }
        });

        findViewById(R.id.visualizationsButton).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                visualizationsButtonPressed(v);
            }
        });

        findViewById(R.id.infoButton).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                infoButtonPressed(v);
            }
        });

        findViewById(R.id.searchButton).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                searchButtonPressed(v);
            }
        });

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
        //turn off loading feedback
        ProgressBar loader = (ProgressBar) findViewById(R.id.loadingSpinner);
        loader.setVisibility(View.GONE);
        
        //possibly show first-run slides
        final SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        if (prefs.getBoolean("firstrun", true)) {
            showHelp();
            prefs.edit().putBoolean("firstrun", false).commit();
        }

        //reset all the togglebuttons that android helpfully restores for us :P
        ImageView imageButton = (ImageView) findViewById(R.id.searchButton);
        imageButton.setActivated(false);

        imageButton = (ImageView) findViewById(R.id.visualizationsButton);
        imageButton.setActivated(false);
        imageButton = (ImageView) findViewById(R.id.timelineButton);
        imageButton.setActivated(false);
        imageButton = (ImageView) findViewById(R.id.infoButton);
        imageButton.setActivated(false);
        
        //start loading the search nodes
        mHandler.post(new Runnable() {
            public void run() {
                if (mAllSearchNodes == null) {
                    loadSearchNodes();
                }
            }
        });
    }
    
    public void loadSearchNodes() {
        Assert.assertNull(mAllSearchNodes);
        
        NodeWrapper[] rawNodes = mController.allNodes();
        //Log.d(TAG, String.format("loaded %d nodes", rawNodes.length));
        
        mAllSearchNodes = new ArrayList<SearchNode>(rawNodes.length);
        for (int i = 0; i < rawNodes.length; i++) {
            if (rawNodes[i] != null) {
                mAllSearchNodes.add(new SearchNode(rawNodes[i]));
            } else {
                //Log.d(TAG, "caught null node"); //FIXME catch this in jni
            }
        }
        //Log.d(TAG, String.format("converted %d nodes", mAllSearchNodes.size()));
    }
    
    public void showHelp() {
        Intent intent = new Intent(this, HelpPopup.class);
        startActivity(intent);
    }
    
    public void forceOrientation() {
        Configuration config = getResources().getConfiguration();
        int screenSize = config.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK;
        //Log.d(TAG, String.format("Size: %d", screenSize));
        int orientation = (screenSize <= Configuration.SCREENLAYOUT_SIZE_NORMAL) ? 
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT : ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
        setRequestedOrientation(orientation);
    }

    public byte[] readFileAsBytes(String filePath) throws java.io.IOException {
        return Helper.readFileAsBytes(this, filePath);
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
        if (!mDoneLoading) {
            Log.d(TAG, "manually finishing the load");
            onBackendLoaded();
            mDoneLoading = true;
        }
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        Log.d(TAG, "surface destroyed");
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
            //Log.d(TAG, "touch end");
            mController.setAllowIdleAnimation(true);
            mController.unhoverNode();
        }
        
        return super.onTouchEvent(event);
    }

    public void visualizationsButtonPressed(View view) {
        dismissPopups();

        //make the button change sooner, and don't let them toggle the button while we're loading
        final ImageView button = (ImageView)findViewById(R.id.visualizationsButton);
        button.setActivated(true);
        
        if (mVisualizationPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.visualizationview, null);
            mVisualizationPopup = new VisualizationPopupWindow(this, mController, popupView);
            mVisualizationPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mVisualizationPopup = null;
                    button.setActivated(false);
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
        final ImageView button = (ImageView)findViewById(R.id.infoButton);
        button.setActivated(true);

        if (mInfoPopup == null) {
            LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
            View popupView = layoutInflater.inflate(R.layout.visualizationview, null);
            mInfoPopup = new InfoPopup(this, mController, popupView);
            mInfoPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                public void onDismiss() {
                    mInfoPopup = null;
                    button.setActivated(false);
                }
            });
            mInfoPopup.showAsDropDown(findViewById(R.id.infoButton));
        }
    }

    public void searchButtonPressed(View view) {
        dismissPopups();

        //make the button change sooner, and don't let them toggle the button while we're loading
        final ImageView button = (ImageView)findViewById(R.id.searchButton);
        button.setActivated(true);
        
        if (mSearchPopup == null) {
            //this can be slow to load, so delay it until the UI updates the button
            mHandler.post(new Runnable(){
                public void run(){
                    
                    if (mAllSearchNodes == null) {
                        loadSearchNodes();
                    }
                    
                    LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
                    View popupView = layoutInflater.inflate(R.layout.searchview, null);
                    mSearchPopup = new SearchPopup(InternetMap.this, mController, popupView);
                    mSearchPopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                        public void onDismiss() {
                            mSearchPopup = null;
                            button.setActivated(false);
                        }
                    });
                    mSearchPopup.showAsDropDown(findViewById(R.id.searchButton));
                    popupView.findViewById(R.id.closeBtn).setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            dismissSearchPopup();
                        }
                    });
                }
            });
        }
    }
    
    public void findHost(final String host) {
        //Log.d(TAG, String.format("find host: %s", host));
        if (!haveConnectivity()) {
            return;
        }
        
        //TODO animate
        final ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
        final ImageView button = (ImageView) findViewById(R.id.searchButton);
        progress.setVisibility(View.VISIBLE);
        button.setVisibility(View.INVISIBLE);
        
        //asn requests are unreliable sometimes, so set a backup timeout
        final Runnable backupTimer = new Runnable() {
            public void run() {
                Log.d(TAG, "backup timer hit");
                showError(getString(R.string.asnAssociationFail));
                //stop animating
                progress.setVisibility(View.INVISIBLE);
                button.setVisibility(View.VISIBLE);
            }
        };
        mHandler.postDelayed(backupTimer, 10000);
        
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
                    mHandler.removeCallbacks(backupTimer);
                } else {
                    Log.d(TAG, addrString);

                    CommonClient.getInstance().getApi().getASNFromIP(addrString).enqueue(new CommonCallback<ASN>() {
                        @Override
                        public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                            progress.setVisibility(View.INVISIBLE);
                            button.setVisibility(View.VISIBLE);
                            mHandler.removeCallbacks(backupTimer);

                            selectNodeByASN(response.body(), false);
                        }

                        @Override
                        public void onRequestFailure(Call<ASN> call, Throwable t) {
                            progress.setVisibility(View.INVISIBLE);
                            button.setVisibility(View.VISIBLE);
                            mHandler.removeCallbacks(backupTimer);

                            String message = getString(R.string.asnAssociationFail);
                            showError(message);
                            Log.d(TAG, message);
                        }
                    });
                }
            }
        }.execute();
    }

    public void dismissSearchPopup() {
        if (mSearchPopup != null) {
            mSearchPopup.dismiss();
        }
    }

    public void youAreHereButtonPressed() {
        //check internet status
        boolean isConnected = haveConnectivity();
        
        if (!isConnected) {
            return;
        }
        
        //asn requests are unreliable sometimes, so set a backup timeout
        final Runnable backupTimer = new Runnable() {
            public void run() {
                Log.d(TAG, "backup timer hit");
                showError(getString(R.string.currentASNFail));
                //stop animating
                ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
                ImageView button = (ImageView) findViewById(R.id.searchButton);
                progress.setVisibility(View.INVISIBLE);
                button.setVisibility(View.VISIBLE);
            }
        };
        mHandler.postDelayed(backupTimer, 10000);

        CommonClient.getInstance().getUserASN(new CommonCallback<ASN>() {
            @Override
            public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                selectNodeByASN(response.body(), true);
            }

            @Override
            public void onRequestFailure(Call<ASN> call, Throwable t) {
                String message = getString(R.string.currentASNFail);
                showError(message);
            }
        });


//        //do an ASN request to get the user's ASN
//        ASNRequest.fetchCurrentASNWithResponseHandler(new ASNResponseHandler() {
//            public void onStart() {
//                Log.d(TAG, "asnrequest start");
//                //animate
//                ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
//                Button button = (Button) findViewById(R.id.searchButton);
//                progress.setVisibility(View.VISIBLE);
//                button.setVisibility(View.INVISIBLE);
//            }
//            public void onFinish() {
//                Log.d(TAG, "asnrequest finish");
//                //stop animating
//                ProgressBar progress = (ProgressBar) findViewById(R.id.searchProgressBar);
//                Button button = (Button) findViewById(R.id.searchButton);
//                progress.setVisibility(View.INVISIBLE);
//                button.setVisibility(View.VISIBLE);
//                mHandler.removeCallbacks(backupTimer);
//            }
//
//            public void onSuccess(JSONObject response) {
//                   selectNodeByASN(response, true);
//            }
//
//            public void onFailure(Throwable e, String response) {
//                //tell the user
//                String message = getString(R.string.currentASNFail);
//                showError(message);
//                Log.d(TAG, message);
//            }
//        });
    }

    public void timelineButtonPressed(View view) {

        final ImageView button = (ImageView)findViewById(R.id.timelineButton);


        if (mInTimelineMode) {
            button.setActivated(false);
            dismissPopups(); //leave timeline mode
        } else {
            button.setActivated(true);
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
                
                //get seekbar -> year mapping
                mTimelineYears = new ArrayList<String>();  
                Iterator<?> it = mTimelineHistory.keys();
                while(it.hasNext()){
                    String year = (String)it.next();
                    mTimelineYears.add(year);
                }
                Assert.assertTrue("Timeline must have at least two years", mTimelineYears.size() > 1);

                timelineBar.setMax(mTimelineYears.size() - 1);
                Collections.sort(mTimelineYears);
                mDefaultYearIndex = mTimelineYears.indexOf(App.getGlobalSettings().getDefaultYear());
                Assert.assertTrue("Can't find 2013 in timeline data", mDefaultYearIndex != -1);
            }

            timelineBar.setProgress(mDefaultYearIndex);
            timelineBar.setVisibility(View.VISIBLE);
            timelineBar.requestLayout(); //hack to work around SurfaceView bug on some phones
            
            mInTimelineMode = true;
            //reset the node popup, the lazy way
            if (mNodePopup != null) mNodePopup.dismiss();
            //get the timeline popup up (even if the slider didn't change)
            createTimelinePopup();
            showTimelinePopup(timelineBar, timelineBar.getProgress());
        }
    }
    
    public void dismissPopups() {
        if (mInTimelineMode) {
            SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
            timelineBar.setVisibility(View.INVISIBLE);
            resetViewAndSetTimeline(mDefaultYearIndex);
            mInTimelineMode = false;
            ImageView button = (ImageView)findViewById(R.id.timelineButton);
            button.setActivated(false);
        }
        if (mNodePopup != null) {
            mNodePopup.dismiss();
        }
        //search and visualization popups dismiss themselves, we can ignore them here
    }
    
    void createTimelinePopup() {
        //Assert.assertNull(mTimelinePopup);
        if (mTimelinePopup != null) {
            mTimelinePopup.dismiss();
        }

        mTimelinePopup = new TimelinePopup(this);
    }
    
    void showTimelinePopup(SeekBar seekBar, int progress) {
        Assert.assertNotNull(mTimelinePopup);
        String year = mTimelineYears.get(progress);
        mTimelinePopup.setData(year, mTimelineHistory.optString(year));
        //Log.d(TAG, year);
        
        //update size/position
        int offset, arrowOffset;
        boolean needsUpdate;
        if (isSmallScreen()) {
            offset = 0;
            arrowOffset = 0;
            needsUpdate = ! mTimelinePopup.isShowing();
        } else {
            //calculate offset to line up with the timelineBar
            int barWidth = seekBar.getWidth();
            int maxProgress = seekBar.getMax();
            int popupWidth = mTimelinePopup.getMeasuredWidth();
            
            Drawable thumb = getResources().getDrawable(R.drawable.seek_thumb_normal_transparent);
            int color = ContextCompat.getColor(InternetMap.this, R.color.colorAccent);
            thumb.setColorFilter(color, android.graphics.PorterDuff.Mode.MULTIPLY);

            float thumbOffset = (float) (thumb.getIntrinsicWidth() / 2.0);
            //now get the  distance from the screen edge to min. thumb centre
            float barOffset = thumbOffset + seekBar.getPaddingLeft();
            
            float innerBarWidth = barWidth - barOffset*2; //measure from the center of the thumb at its max/min
            float progressRelativeXCenter = (innerBarWidth * (float)progress / maxProgress);
            float progressXCenter = progressRelativeXCenter + barOffset;
            offset = (int)(progressXCenter - popupWidth/2.0); //center over the thumb
            
            //get the arrow in the right place even at the edges
            //note: I'm assuming barWidth == screenWidth
            //also, we now need to keep the popup on-screen manually.
            int end = barWidth - popupWidth;
            if (offset < 0) {
                arrowOffset = offset;
                offset = 0;
            } else if (offset > end) {
                arrowOffset = offset - end;
                offset = end;
            } else {
                arrowOffset = 0;
            }
            
            needsUpdate = true;
        }
        
        if (needsUpdate) {
            mTimelinePopup.showWithOffsets(offset, arrowOffset);
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
            resetViewAndSetTimeline(seekBar.getProgress());
        }
    }
    
    public void resetViewAndSetTimeline(final int yearIndex) {
        if (mNodePopup != null) {
            mNodePopup.dismiss();
        }

        //Assert.assertNotNull(mTimelinePopup);
        if (mTimelinePopup != null) {
            mTimelinePopup.showLoadingText();
        }
        
        mCameraResetHandler = new CallbackHandler(){
            public void handle() {
                String year = mTimelineYears.get(yearIndex);
                mController.setTimelinePoint(year);
                if (mTimelinePopup != null) {
                    mTimelinePopup.dismiss();
                    mTimelinePopup = null;
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
        return Helper.haveConnectivity(this);
    }
    
    public void showError(String message) {
        Helper.showError(this, message);
    }

    public void selectNodeByASN(ASN asn, boolean cacheIndex) {
        try {
            NodeWrapper node = mController.nodeByAsn(asn.getASNString());
            if (node != null) {
                if (cacheIndex) {
                    mUserNodeIndex = node.index;
                }
                mController.updateTargetForIndex(node.index);
            } else {
                showError(getString(R.string.asnAssociationFail));
            }
        } catch (Exception e) {
            Log.d(TAG, String.format("can't parse response"));
            showError(getString(R.string.asnAssociationFail));
        }
    }

    public void selectNodeByASNOld(JSONObject response, boolean cacheIndex) {
        //expected response format: {"payload":"ASxxxx"}
        try {
            String asnWithAS = response.getString("payload");
            String asnString = asnWithAS.substring(2);
            //.d(TAG, String.format("2asn: %s", asnString));
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
        return Helper.isSmallScreen(this);
    }

    //called from c++ via threadsafeShowNodePopup
    public void showNodePopup() {
        //get the current node
        int index = mController.targetNodeIndex();
        //Log.d(TAG, String.format("node at index %d", index));
        NodeWrapper node = mController.nodeAtIndex(index);
        if (node == null) {
            //Log.d(TAG, "is null");
            if (mNodePopup != null) {
                mNodePopup.dismiss();
            }
        } else {
            //node is ok; show the popup
            //Log.d(TAG, String.format("has index %d and asn %s", node.index, node.asn));
            if (mNodePopup == null) {
                LayoutInflater layoutInflater = (LayoutInflater)getBaseContext().getSystemService(LAYOUT_INFLATER_SERVICE);
                View popupView;

                boolean isSimulated;

                if (mInTimelineMode) {
                    popupView = layoutInflater.inflate(R.layout.nodetimelineview, null);
                    //get the year to find out if data is simulated
                    SeekBar timelineBar = (SeekBar) findViewById(R.id.timelineSeekBar);
                    String yearStr = this.mTimelineYears.get(timelineBar.getProgress());
                    isSimulated = App.getGlobalSettings().getSimulatedYears().contains(yearStr);
                } else {
                    isSimulated = false;
                    popupView = layoutInflater.inflate(R.layout.nodeview, null);
                    if (isSmallScreen()) {
                        popupView.findViewById(R.id.leftArrow).setVisibility(View.GONE);
                    }
                }
                mNodePopup = new NodePopup(this, popupView, mInTimelineMode, isSimulated);
                mNodePopup.setOnDismissListener(new PopupWindow.OnDismissListener() {
                    public void onDismiss() {
                        mNodePopup = null;
                        mController.deselectCurrentNode();
                        mController.resetZoomAndRotationAnimated(isSmallScreen());
                    }
                });
                popupView.findViewById(R.id.closeBtn).setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        dismissNodePopup();
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
                gravity = Gravity.CENTER;
                width = mainView.getWidth();
                if (! isSmallScreen()) {
                    //full width looks odd on tablets
                    width = width / 2;
                }
            } else if (isSmallScreen()) {
                gravity = Gravity.BOTTOM;
                width = LayoutParams.MATCH_PARENT;
            } else {
                gravity = Gravity.CENTER_VERTICAL | Gravity.RIGHT;
                width = mainView.getWidth() / 2;
            }
            mNodePopup.setWindowLayoutMode(width, LayoutParams.WRAP_CONTENT);
            mNodePopup.setWidth(width);
            int height = mNodePopup.getMeasuredHeight();
            mNodePopup.setHeight(height); //work around weird bugs
            
            //now that the height is calculated, we can calculate any offset
            int offset;
            if (mInTimelineMode) {
                //move it up by half the height
                offset = -height/2;
            } else {
                offset = 0;
            }
            if (gravity != Gravity.BOTTOM) {
                //account for the top bar
                int location[] = new int[2];
                mainView.getLocationOnScreen(location);
                int top = location[1];
                offset += top / 2;
            }
            
            mNodePopup.showAtLocation(mainView, gravity, 0, offset);
            //Log.d(TAG, String.format("showing : %d", mNodePopup.getHeight()));
        }
    }
    
    //callbacks from the nodePopup UI
    public void dismissNodePopup() {
        if (mNodePopup != null) {
            mNodePopup.dismiss();
        }
    }
    
    public void runTraceroute(View unused) throws JSONException, UnsupportedEncodingException{
        Log.d(TAG, "TODO: traceroute");
      //check internet status
        boolean isConnected = haveConnectivity();
        
        if (!isConnected) {
            return;
        }
        String asn = "AS15169";
//        ASNRequest.fetchIPsForASN(asn, new ASNResponseHandler() {
//            public void onStart() {
//
//            }
//            public void onFinish() {
//
//            }
//
//            public void onSuccess(JSONObject response) {
//                try {
//                	//Try and get legit payload here
//                    Log.d(TAG, String.format("payload: %s", response));
//                } catch (Exception e) {
//                    Log.d(TAG, String.format("Can't parse response: %s", response.toString()));
//                    showError(getString(R.string.tracerouteStartIPFail));
//                }
//            }
//
//            public void onFailure(Throwable e, String response) {
//                String message = getString(R.string.tracerouteStartIPFail);
//                showError(message);
//                Log.d(TAG, message);
//            }
//        });
        
    }

    //native wrappers
    public native boolean nativeOnCreate(boolean smallScreen);
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

    @Override
    public void onBackPressed(){

        if (mNodePopup != null || mInTimelineMode) {
            dismissPopups();
        }else {
            super.onBackPressed();
        }

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
            //Log.d(TAG, "tap!");
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
