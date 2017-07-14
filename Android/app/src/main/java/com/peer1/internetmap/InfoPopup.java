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
        
        String[] values = new String[4];
        values[0] = context.getString(R.string.infoHelp);
        values[1] = context.getString(R.string.infoSales);
        values[2] = context.getString(R.string.infoOpenSource);
        values[3] = context.getString(R.string.infoCredits);
        
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
                    doSales();
                    break;
                case 2:
                    openOpenSourcePage();
                    break;
                case 3:
                    doCredits();
                    break;
                default:
                    Timber.e("can't happen");
                }

                InfoPopup.this.dismiss();
                dismissedViaSelection = false;
            }
        });
    }

    private void openOpenSourcePage() {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/steamclock/internetmap"));
        mContext.startActivity(browserIntent);
    }

    private void doSales() {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://www.cogecopeer1.com/contact/"));
        mContext.startActivity(browserIntent);
    }
    
    private void doCredits() {
        Intent intent = new Intent(mContext, CreditsPopup.class);
        mContext.startActivity(intent);
    }

}
