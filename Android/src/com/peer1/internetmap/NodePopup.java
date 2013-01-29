package com.peer1.internetmap;

import java.util.ArrayList;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.text.TextPaint;
import android.util.AttributeSet;
import android.view.View;
import android.view.ViewGroup;
import android.widget.PopupWindow;
import android.widget.TextView;

/**
 * TODO: document your custom view class.
 */
public class NodePopup extends PopupWindow {
    private Context mContext;
    
    public NodePopup(Context context, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        mContext = context;
        setBackgroundDrawable(new ColorDrawable(Color.argb(200, 0, 0, 0))); //black bg, a teensy bit translucent
        
        //FIXME calculate appropriate size
        setWidth(300);
        setHeight(200);
    }
    
    public void setNode(NodeWrapper node) {
        setNode(node, false);
    }
    public void setNode(NodeWrapper node, boolean isUsersNode) {
        //set up content
        ArrayList<String> strings = new ArrayList<String>(4);
        if (isUsersNode) {
            strings.add(mContext.getString(R.string.youarehere));
        }
        if (!node.textDescription.isEmpty()) {
            strings.add(node.textDescription);
        }
        strings.add("AS" + node.asn);
        if (!node.typeString.isEmpty()) {
            strings.add(node.typeString);
        }
        
        //split into title/rest
        String title = strings.get(0);
        StringBuilder mainText = new StringBuilder();
        if (strings.size() <= 1) {
            //default text
            mainText.append(mContext.getString(R.string.nodata));
        } else {
            //join the strings with \n
            mainText.append(strings.get(1));
            for (int i = 2; i < strings.size(); i++) {
                mainText.append("\n");
                mainText.append(strings.get(i));
            }
        }
        
        //put it in the right views
        TextView titleView = (TextView) getContentView().findViewById(R.id.titleView);
        titleView.setText(title);
        TextView mainTextView = (TextView) getContentView().findViewById(R.id.mainTextView);
        mainTextView.setText(mainText); 
    }
}
