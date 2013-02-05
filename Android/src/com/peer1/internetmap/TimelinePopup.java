package com.peer1.internetmap;

import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.text.Html;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.PopupWindow;
import android.widget.TextView;

/**
 * Timeline information popup
 */
public class TimelinePopup extends PopupWindow {
    private static String TAG = "TimelinePopup";
    
    public TimelinePopup(Context context, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        
        setWidth(300); //FIXME
        setHeight(200);
    }
    
    public void setData(String year, String mainText) {
        //put it in the right views
        TextView titleView = (TextView) getContentView().findViewById(R.id.titleView);
        titleView.setText(year);
        TextView mainTextView = (TextView) getContentView().findViewById(R.id.mainTextView);
        mainTextView.setText(Html.fromHtml(mainText));

        //recalculate the size  - FIXME this is still refusing to work
        getContentView().requestLayout();
        int height = getContentView().getMeasuredHeight();
        Log.d(TAG, String.format("height: %d", height));
        //if (height > 0) setHeight(height);
    }
}
