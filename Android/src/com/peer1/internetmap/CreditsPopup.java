package com.peer1.internetmap;

import java.io.IOException;

import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.PopupWindow;

public class CreditsPopup extends PopupWindow{
    private static String TAG = "CreditsPopup";

    public CreditsPopup(final InternetMap context, View view) {
        super(view, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        setOutsideTouchable(true);
        setFocusable(true);

        //close button
        View closeButton = getContentView().findViewById(R.id.closeBtn);
        closeButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                CreditsPopup.this.dismiss();
            }
        });

        //set text
        WebView webView = (WebView) getContentView().findViewById(R.id.textView);
        try {
            String html = new String(context.readFileAsBytes("data/credits.html"));
            webView.loadData(html, "text/html", null);
        } catch (IOException e) {
            e.printStackTrace();
        }
        //some magic to make the webview transparent despite bugs
        webView.setBackgroundColor(context.getResources().getColor(R.color.translucentBlack));
    }
}
