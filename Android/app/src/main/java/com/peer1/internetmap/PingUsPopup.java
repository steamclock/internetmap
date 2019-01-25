package com.peer1.internetmap;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.MenuItem;
import android.view.View;

/**
 *
 */
public class PingUsPopup extends BaseActivity {

    // Activity requests
    public static int REQUEST_PING_IP = 220;

    // Intent Extra result values
    public static String RESULT_EXTRA_IP = "RESULT_EXTRA_IP";

    private static String TAG = "ContactPopup";

    private View loadingSpinner;
    private RecyclerView list;
    private PingUsAdapter listAdapter;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.ping_us);
        getActionBar().setDisplayHomeAsUpEnabled(true);

        loadingSpinner = findViewById(R.id.loadingSpinner);
        list = findViewById(R.id.ping_us_location_recycler);

        loadRecycler();
    }

    private void loadRecycler() {
        // Content has fixed size, can actually set this!
        list.setHasFixedSize(true);

        // Setup layout manager and adapter
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        list.setLayoutManager(layoutManager);
        listAdapter = new PingUsAdapter();
        listAdapter.setListener(new PingUsAdapter.Listener() {
            @Override
            public void onClicked(String ipAddress) {
                Intent intent = new Intent();
                intent.putExtra(RESULT_EXTRA_IP, ipAddress);
                setResult(RESULT_OK, intent);
                finish();
            }
        });

        list.setAdapter(listAdapter);
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
