package com.peer1.internetmap;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import com.peer1.internetmap.utils.AppUtils;

import java.io.IOException;

/**
 * ContactPopup popup, shown from info menu. Uses WebView to render data from contact.html asset.
 */
public class ContactPopup extends BaseActivity {
    private static String TAG = "ContactPopup";

    private View loadingSpinner;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.credits);
        getActionBar().setDisplayHomeAsUpEnabled(true);

        loadingSpinner = findViewById(R.id.loadingSpinner);

        WebView webView = (WebView) findViewById(R.id.textView); // Bad name.
        webView.clearCache(true);
        webView.clearHistory();
        setJSClient(webView);

        try {
            loadingSpinner.setVisibility(View.VISIBLE);
            webView.loadUrl("file:///android_asset/data/contact.html");
        } catch (Exception e) {
            e.printStackTrace();
        }
        // Some magic to make the webview transparent despite bugs
        webView.setBackgroundColor(Color.TRANSPARENT);
    }

    public void setJSClient(WebView webView) {

        WebViewClient webviewClient = new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                loadingSpinner.setVisibility(View.GONE);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return super.shouldOverrideUrlLoading(view, request);
            }
        };

        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
        webView.setWebViewClient(webviewClient);
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
