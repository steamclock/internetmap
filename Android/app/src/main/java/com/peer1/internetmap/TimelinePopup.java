package com.peer1.internetmap;

import junit.framework.Assert;
import android.content.Context;
import android.text.Html;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.widget.RelativeLayout;
import android.view.animation.TranslateAnimation;
import android.widget.TextView;

/**
 * Timeline popup; allows users to change the data sets being shown in the visualizations
 */
public class TimelinePopup {
    private static String TAG = "TimelinePopup";
    private Context mContext;
    private int mArrowOffset;
    private View mView;
    private RelativeLayout mParentView;
    private int mWidthMode;
    private boolean mIsShowing;
    
    public TimelinePopup(InternetMap context) {
        mContext = context;
        LayoutInflater layoutInflater = (LayoutInflater)context.getBaseContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        mView = layoutInflater.inflate(R.layout.timelinepopup, null);
        
        if (context.isSmallScreen()) {
            //padding instead of arrow, and full width
            mView.findViewById(R.id.arrow).setVisibility(View.GONE);
            mView.findViewById(R.id.LinearLayout1).setPadding(0, 0, 0, 10);
            
            mWidthMode = LayoutParams.MATCH_PARENT;
            View content = mView.findViewById(R.id.mainTextView);
            android.view.ViewGroup.LayoutParams params = content.getLayoutParams();
            params.width = LayoutParams.MATCH_PARENT;
            content.setLayoutParams(params);
        } else {
            mWidthMode = LayoutParams.WRAP_CONTENT;
        }
        
        mParentView = (RelativeLayout) context.findViewById(R.id.mainLayout);
        Assert.assertNotNull(mParentView);
    }
    
    public void setData(String year, String mainText) {
        //put it in the right views
        TextView titleView = (TextView) mView.findViewById(R.id.titleView);
        titleView.setText(year);
        TextView mainTextView = (TextView) mView.findViewById(R.id.mainTextView);
        if (mainText.isEmpty()) {
            mainTextView.setText(mContext.getString(R.string.nodata));
        } else {
            mainTextView.setText(Html.fromHtml(mainText));
        }
    }
    
    //note: don't call this twice in a row
    public void showLoadingText() {
        TextView titleView = (TextView) mView.findViewById(R.id.titleView);
        CharSequence year = titleView.getText();
        titleView.setText(String.format(mContext.getString(R.string.loading), year));
    }

    /**
     * For some reason popupwindow doesn't have this.
     * @return the real width of the popup based on the layout.
     */
    public int getMeasuredWidth() {
        //update the layout for current data
        mView.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
        return mView.getMeasuredWidth();
    }
    
    public boolean isShowing() {
        return mIsShowing;
    }
    
    /**
     * show/update this popup.
     * 
     * updates both the regular positioning and the arrow position
     */
    public void showWithOffsets(int xOffset, int arrowOffset) {
        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(mWidthMode, LayoutParams.WRAP_CONTENT);
        params.addRule(RelativeLayout.ABOVE, R.id.timelineSeekBar);
        params.setMargins(xOffset, 0, 0, 0);
        mParentView.removeView(mView);
        mParentView.addView(mView, params);
        
        View arrow = mView.findViewById(R.id.arrow);
        //arrow.setTranslationX(arrowOffset);
        //settranslationx isn't available in api 10, so we work around this with an animation.
        TranslateAnimation anim = new TranslateAnimation(mArrowOffset, arrowOffset, 0, 0);
        anim.setFillAfter(true);
        anim.setDuration(100);
        arrow.startAnimation(anim);
        mArrowOffset = arrowOffset;
        
        mIsShowing = true;
    }

    public void dismiss() {
        mParentView.removeView(mView);
        mIsShowing = false;
    }
}
