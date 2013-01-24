package com.peer1.internetmap;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

public class VisualizationArrayAdapter extends ArrayAdapter<String> {
    public int selectedRow;

    public VisualizationArrayAdapter(Context context, int resource, int textViewResourceId, String[] objects) {
        super(context, resource, textViewResourceId, objects);
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        TextView textView = (TextView) super.getView(position, convertView, parent);
        if (position == selectedRow) {
            textView.setBackgroundColor(Color.RED);
            textView.setTextColor(Color.BLACK);
        }else {
            textView.setBackgroundColor(Color.parseColor("#80000000"));
            textView.setTextColor(Color.WHITE);
        }
        return textView;
    }
}
