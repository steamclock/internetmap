package com.peer1.internetmap;

import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.content.ContextCompat;
import android.view.MenuItem;
import android.view.View;
import android.webkit.WebView;
import android.widget.Button;

import com.peer1.internetmap.utils.AppUtils;

import java.io.IOException;

/**
 * About popup, shown from info menu. Uses WebView to render data from credits.html asset.
 */
public class AboutPopup extends BaseActivity {
    private static String TAG = "AboutPopup";

    private Button bottomButton;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.credits);
        getActionBar().setDisplayHomeAsUpEnabled(true);

        bottomButton = (Button)findViewById(R.id.bottom_button);
        bottomButton.setText(getString(R.string.infoMoreAboutLink));
        bottomButton.setVisibility(View.VISIBLE);
        bottomButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showCogecoUrl();
            }
        });

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

    // Until we can fix loading feedback, we are not going to load this content in an embedded WebView
//    private void showCogecoWebView() {
//        Intent intent = new Intent(AboutPopup.this, WebViewPopup.class);
//        intent.putExtra(WebViewPopup.EXTRA_LOAD_URL, "https://cogecopeer1.com");
//        intent.putExtra(WebViewPopup.EXTRA_TITLE, getString(R.string.infoMoreAboutLink));
//        startActivity(intent);
//    }

    private void showCogecoUrl() {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://cogecopeer1.com"));
        startActivity(browserIntent);
    }
}
