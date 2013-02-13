package com.peer1.internetmap;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;


public class VisualizationPopupWindow extends PopupWindow{
    private Context mContext;

    private class VisualizationArrayAdapter extends ArrayAdapter<String> {
        public int selectedRow;

        public VisualizationArrayAdapter(Context context, int resource, int textViewResourceId, String[] objects) {
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

    public VisualizationPopupWindow(final InternetMap context, final MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setOutsideTouchable(true);
        setFocusable(true);
        mContext = context;

        final ListView listView = (ListView) getContentView().findViewById(R.id.visualizationList);
        String[] values = controller.visualizationNames();
        final VisualizationArrayAdapter adapter = new VisualizationArrayAdapter(context, android.R.layout.simple_list_item_1, android.R.id.text1, values);
        adapter.selectedRow = context.mCurrentVisualization;
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                context.setVisualization(position);
                VisualizationPopupWindow.this.dismiss();
            }
        });
    }


}
