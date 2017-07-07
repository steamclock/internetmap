package com.peer1.internetmap;

import java.io.IOException;

import android.annotation.SuppressLint;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NavUtils;
import android.view.MenuItem;
import android.webkit.WebView;

public class CreditsPopup extends BaseActivity {
    private static String TAG = "CreditsPopup";

    @SuppressLint("NewApi")
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.credits);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            getActionBar().setDisplayHomeAsUpEnabled(true);
        }

        //set text
        WebView webView = (WebView) findViewById(R.id.textView);
        try {
            String html = new String(Helper.readFileAsBytes(this, "data/credits.html"));
            webView.loadData(html, "text/html", null);
        } catch (IOException e) {
            e.printStackTrace();
        }
        //some magic to make the webview transparent despite bugs
        webView.setBackgroundColor(getResources().getColor(R.color.translucentBlack));
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case android.R.id.home:
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
