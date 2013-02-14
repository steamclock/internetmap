package com.peer1.internetmap;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;

//note: a lot of this is c&p from VisualizationPopupWindow. if we get a 3rd simple menu we should abstract it out.
public class InfoPopup extends PopupWindow{
    private static String TAG = "InfoPopup";
    private Context mContext;

    private class InfoArrayAdapter extends ArrayAdapter<String> {
        public int selectedRow;

        public InfoArrayAdapter(Context context, int resource, int textViewResourceId, String[] objects) {
            super(context, resource, textViewResourceId, objects);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            TextView textView = (TextView) super.getView(position, convertView, parent);
            if (position == selectedRow) {
                textView.setBackgroundColor(mContext.getResources().getColor(R.color.orange));
                textView.setTextColor(Color.BLACK);
            } else {
                textView.setBackgroundColor(Color.TRANSPARENT);
                textView.setTextColor(Color.WHITE);
            }
            return textView;
        }
    }

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
        
        final InfoArrayAdapter adapter = new InfoArrayAdapter(context, android.R.layout.simple_list_item_1, android.R.id.text1, values);
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
