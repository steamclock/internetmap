package com.peer1.internetmap;

import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.PopupWindow;

public class InfoPopup extends PopupWindow{
    private static String TAG = "InfoPopup";

    public InfoPopup(final InternetMap context, final MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setOutsideTouchable(true);
        setFocusable(true);

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
                    Log.d(TAG, "TODO: sales");
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


}
