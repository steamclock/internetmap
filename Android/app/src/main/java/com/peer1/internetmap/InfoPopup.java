package com.peer1.internetmap;

import android.content.Intent;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.PopupWindow;

import timber.log.Timber;

/**
 * Info menu
 */
public class InfoPopup extends PopupWindow {
    private static String TAG = "InfoPopup";
    private InternetMap mContext;

    private boolean dismissedViaSelection;
    public boolean wasDismissedViaSelection() {
        return dismissedViaSelection;
    }

    public InfoPopup(final InternetMap context, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
        setOutsideTouchable(true);
        setFocusable(true);
        mContext = context;

        final ListView listView = (ListView) getContentView().findViewById(R.id.visualizationList);
        
        String[] values = new String[5];
        values[0] = context.getString(R.string.infoHelp);
        values[1] = context.getString(R.string.infoAboutLink);
        values[2] = context.getString(R.string.infoContactLink);
        values[3] = context.getString(R.string.infoOpenSource);
        values[4] = context.getString(R.string.infoCredits);
        
        final ArrayAdapter<String> adapter = new ArrayAdapter<String>(context, R.layout.view_info_popup_item, android.R.id.text1, values);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                dismissedViaSelection = true;
                switch (position) {
                    case 0:
                        mContext.showIntroduction();
                        break;
                    case 1:
                        showAbout();
                        break;
                    case 2:
                        showContact();
                        break;
                    case 3:
                        showOpenSource();
                        break;
                    case 4:
                        showCredits();
                        break;
                    default:
                        Timber.e("can't happen");
                }

                InfoPopup.this.dismiss();
                dismissedViaSelection = false;
            }
        });
    }

    private void showAbout() {
        Intent intent = new Intent(mContext, AboutPopup.class);
        mContext.startActivity(intent);
    }

    private void showContact() {
        Intent intent = new Intent(mContext, ContactPopup.class);
        mContext.startActivity(intent);
    }

    private void showOpenSource() {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/steamclock/internetmap"));
        mContext.startActivity(browserIntent);
    }

    private void showCredits() {
        Intent intent = new Intent(mContext, CreditsPopup.class);
        mContext.startActivity(intent);
    }

}
