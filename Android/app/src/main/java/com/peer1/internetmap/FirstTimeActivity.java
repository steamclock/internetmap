package com.peer1.internetmap;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;

/**
 * Shown to the user when the app is run for the first time, or if they select Help from the
 * info menu.
 */
public class FirstTimeActivity extends BaseActivity {

    private Button exploreButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_first_time);

        exploreButton = (Button)findViewById(R.id.explore_button);
        exploreButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
    }
}
