package com.peer1.internetmap;

import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.text.Html;
import android.util.Log;
import android.view.View;
import android.widget.PopupWindow;
import android.widget.TextView;

/**
 * Timeline information popup
 */
public class TimelinePopup extends PopupWindow {
    private static String TAG = "TimelinePopup";
    private Context mContext;
    
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

    /**
     * For some reason popupwindow doesn't have this.
     * @return the real width of the popup based on the layout.
     */
    public int getMeasuredWidth() {
        //update the layout for current data
        getContentView().measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
        return getContentView().getMeasuredWidth();
    }
}
