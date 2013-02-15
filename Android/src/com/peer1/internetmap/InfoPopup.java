package com.peer1.internetmap;

import junit.framework.Assert;
import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.PopupWindow;

public class InfoPopup extends PopupWindow{
    private static String TAG = "InfoPopup";
    private InternetMap mContext;

    public InfoPopup(final InternetMap context, final MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setOutsideTouchable(true);
        setFocusable(true);
        mContext = context;

        final ListView listView = (ListView) getContentView().findViewById(R.id.visualizationList);
        
        String[] values = new String[3];
        values[0] = context.getString(R.string.infoHelp);
        values[1] = context.getString(R.string.infoSales);
        values[2] = context.getString(R.string.infoCredits);
        
        final ArrayAdapter<String> adapter = new ArrayAdapter<String>(context, android.R.layout.simple_list_item_1, android.R.id.text1, values);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                switch (position) {
                case 0: //help
                    Log.d(TAG, "TODO: help");
                    break;
                case 1: //sales
                    doSales();
                    break;
                case 2: //credits
                    Log.d(TAG, "TODO: credits");
                    break;
                default:
                    Log.e(TAG, "can't happen");
                }
                InfoPopup.this.dismiss();
            }
        });
    }

    private void doSales() {
        LayoutInflater layoutInflater = (LayoutInflater)mContext.getBaseContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View popupView = layoutInflater.inflate(R.layout.contactsales, null);
        SalesPopup popup = new SalesPopup(mContext, popupView);
        //show it
        View mainView = mContext.findViewById(R.id.mainLayout);
        Assert.assertNotNull(mainView);
        popup.setWidth(mainView.getWidth());
        popup.setHeight(mainView.getHeight());
        int gravity = Gravity.BOTTOM; //to avoid offset issues
        popup.showAtLocation(mainView, gravity, 0, 0);
    }

}
