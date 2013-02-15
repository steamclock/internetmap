package com.peer1.internetmap;

import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.PopupWindow;

public class SalesPopup extends PopupWindow{
    private static String TAG = "SalesPopup";

    public SalesPopup(final InternetMap context, View view) {
        super(view, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        setOutsideTouchable(true);
        setFocusable(true);

        View closeButton = getContentView().findViewById(R.id.closeBtn);
        closeButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                SalesPopup.this.dismiss();
            }
        });

        View submitButton = getContentView().findViewById(R.id.submitButton);
        submitButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                Log.d(TAG, "TODO: submit");
                SalesPopup.this.dismiss();
            }
        });
    }


}
