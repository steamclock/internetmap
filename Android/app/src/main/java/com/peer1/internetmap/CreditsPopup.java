package com.peer1.internetmap;

import java.io.IOException;

import android.graphics.Color;
import android.os.Bundle;
import android.support.v4.content.ContextCompat;
import android.view.MenuItem;
import android.view.View;
import android.webkit.WebView;
import android.widget.TextView;

import com.peer1.internetmap.utils.AppUtils;

/**
 * Credits popup, shown from info menu. Uses WebView to render data from credits.html asset.
 */
public class CreditsPopup extends BaseActivity {
    private static String TAG = "CreditsPopup";

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.credits);
        getActionBar().setDisplayHomeAsUpEnabled(true);

        int versionCode = BuildConfig.VERSION_CODE;
        String versionName = BuildConfig.VERSION_NAME;
        TextView appVersion = (TextView)findViewById(R.id.app_version);
        appVersion.setVisibility(View.VISIBLE);
        appVersion.setText(String.format("%s (%d)", versionName, versionCode));

        WebView webView = (WebView) findViewById(R.id.textView);
        try {
            String html = new String(AppUtils.readFileAsBytes(this, "data/credits.html"));
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
