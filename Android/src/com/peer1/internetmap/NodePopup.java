package com.peer1.internetmap;

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
    public NodePopup(Context context, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        setBackgroundDrawable(new ColorDrawable(Color.argb(200, 0, 0, 0))); //black bg, a teensy bit translucent
    }
    
    public void setNode(NodeWrapper node) {
        //set up content
        TextView mainTextView = (TextView) getContentView().findViewById(R.id.mainTextView);
        String mainText = node.textDescription.isEmpty() ? "unnamed" : node.textDescription;
        mainTextView.setText(mainText);
    }
}
