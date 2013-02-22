package com.peer1.internetmap;

import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.text.Html;
import android.util.Log;
import android.view.View;
import android.view.animation.TranslateAnimation;
import android.widget.PopupWindow;
import android.widget.TextView;

/**
 * Timeline information popup
 */
public class TimelinePopup extends PopupWindow {
    private static String TAG = "TimelinePopup";
    private Context mContext;
    private int mArrowOffset;
    
    public TimelinePopup(Context context, View view) {
        super(view);
        mContext = context;
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setHeight(100); //a fake height so that showAsDropDown doesn't mess up.
    }
    
    public void setData(String year, String mainText) {
        //put it in the right views
        TextView titleView = (TextView) getContentView().findViewById(R.id.titleView);
        titleView.setText(year);
        TextView mainTextView = (TextView) getContentView().findViewById(R.id.mainTextView);
        if (mainText.isEmpty()) {
            mainTextView.setText(mContext.getString(R.string.nodata));
        } else {
            mainTextView.setText(Html.fromHtml(mainText));
        }
    }
    
    //note: don't call this twice in a row
    public void showLoadingText() {
        TextView titleView = (TextView) getContentView().findViewById(R.id.titleView);
        CharSequence year = titleView.getText();
        titleView.setText(String.format(mContext.getString(R.string.loading), year));
    }

    /**
     * For some reason popupwindow doesn't have this.
     * @return the real width of the popup based on the layout.
     */
    public int getMeasuredWidth() {
        //update the layout for current data
        getContentView().measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
        return getContentView().getMeasuredWidth();
    }
    
    /**
     * update both the regular positioning and the arrow position
     */
    public void updateOffsets(View seekBar, int xOffset, int arrowOffset) {
        update(seekBar, xOffset, 0, -1, -1);
        
        View arrow = getContentView().findViewById(R.id.arrow);
        //arrow.setTranslationX(arrowOffset);
        //settranslationx isn't available in api 10, so we work around this with an animation.
        TranslateAnimation anim = new TranslateAnimation(mArrowOffset, arrowOffset, 0, 0);
        anim.setFillAfter(true);
        anim.setDuration(100);
        arrow.startAnimation(anim);
        Log.d(TAG, "animating");
        mArrowOffset = arrowOffset;
    }
}
