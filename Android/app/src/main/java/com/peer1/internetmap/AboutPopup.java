package com.peer1.internetmap;

import android.graphics.Color;
import android.os.Bundle;
import android.support.v4.content.ContextCompat;
import android.view.MenuItem;
import android.webkit.WebView;

import com.peer1.internetmap.utils.AppUtils;

import java.io.IOException;

/**
 * About popup, shown from info menu. Uses WebView to render data from credits.html asset.
 */
public class AboutPopup extends BaseActivity {
    private static String TAG = "AboutPopup";

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.credits);
        getActionBar().setDisplayHomeAsUpEnabled(true);

        WebView webView = (WebView) findViewById(R.id.textView);
        try {
            String html = new String(AppUtils.readFileAsBytes(this, "data/about.html"));
            webView.loadData(html, "text/html", null);
        } catch (IOException e) {
            e.printStackTrace();
        }
        // Some magic to make the webview transparent despite bugs
        webView.setBackgroundColor(Color.TRANSPARENT);
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
