package com.peer1.internetmap;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;

public class VisualizationArrayAdapter extends ArrayAdapter<String> {
    public int selectedRow;

    public VisualizationArrayAdapter(Context context, int resource, int textViewResourceId, String[] objects) {
        super(context, resource, textViewResourceId, objects);
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        View view = super.getView(position, convertView, parent);
        if (position == selectedRow) {
            view.setBackgroundColor(Color.RED);
        }else {
            view.setBackgroundColor(Color.parseColor("#80000000"));
        }
        return view;
    }
}
