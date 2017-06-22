package com.peer1.internetmap;

import junit.framework.Assert;
import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.PopupWindow;

public class InfoPopup extends PopupWindow {
    private static String TAG = "InfoPopup";
    private InternetMap mContext;

    public InfoPopup(final InternetMap context, final MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
        setOutsideTouchable(true);
        setFocusable(true);
        mContext = context;

        final ListView listView = (ListView) getContentView().findViewById(R.id.visualizationList);
        
        String[] values = new String[4];
        values[0] = context.getString(R.string.infoHelp);
        values[1] = context.getString(R.string.infoSales);
        values[2] = context.getString(R.string.infoLink);
        values[3] = context.getString(R.string.infoCredits);
        
        final ArrayAdapter<String> adapter = new ArrayAdapter<String>(context, R.layout.view_info_popup_item, android.R.id.text1, values);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                switch (position) {
                case 0: //help
                    mContext.showHelp();
                    break;
                case 1: //sales
                    doSales();
                    break;
                case 2: //link
                    Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("http://www.peer1.com/node/3325"));
                    mContext.startActivity(browserIntent);
                    break;
                case 3: //credits
                    doCredits();
                    break;
                default:
                    Log.e(TAG, "can't happen");
                }
                InfoPopup.this.dismiss();
            }
        });
    }

    private void doSales() {
        Intent intent = new Intent(mContext, SalesPopup.class);
        mContext.startActivity(intent);
    }
    
    private void doCredits() {
        Intent intent = new Intent(mContext, CreditsPopup.class);
        mContext.startActivity(intent);
    }

}
