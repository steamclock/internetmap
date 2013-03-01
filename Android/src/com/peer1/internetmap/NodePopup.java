package com.peer1.internetmap;

import java.util.ArrayList;

import android.content.Context;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.PopupWindow;
import android.widget.TextView;

/**
 * TODO: document your custom view class.
 */
public class NodePopup extends PopupWindow {
    private static String TAG = "NodePopup";
    private Context mContext;
    private boolean mIsTimelineView;
    private boolean mIsSimulated;
    
    public NodePopup(Context context, View view, boolean isTimelineView, boolean isSimulated) {
        super(view);
        mContext = context;
        mIsTimelineView = isTimelineView;
        mIsSimulated = isSimulated;
    }
    
    public void setNode(NodeWrapper node) {
        setNode(node, false);
    }
    public void setNode(NodeWrapper node, boolean isUsersNode) {
        //set up content
        String title;
        if (mIsSimulated) {
            title = mContext.getString(R.string.simulated);
        } else {
            ArrayList<String> strings = new ArrayList<String>(4);
            if (isUsersNode && !mIsTimelineView) {
                strings.add(mContext.getString(R.string.youarehere));
            }
            String desc = node.friendlyDescription();
            if (!desc.isEmpty()) {
                strings.add(desc);
            }
            strings.add("AS" + node.asn);
            if (!mIsTimelineView) {
                if (!node.typeString.isEmpty()) {
                    strings.add(node.typeString);
                }
                //FIXME show # connections only on tablets..?
                if (node.numberOfConnections == 1) {
                    strings.add(mContext.getString(R.string.oneconnection));
                } else {
                    //<num> connections
                    strings.add(String.format(mContext.getString(R.string.nconnections), node.numberOfConnections));
                }
            }

            //split into title/rest
            title = strings.get(0);
            if (!mIsTimelineView) {
                StringBuilder mainText = new StringBuilder();
                if (strings.size() <= 1) {
                    //default text
                    mainText.append(mContext.getString(R.string.nomoredata));
                } else {
                    //join the strings with \n
                    mainText.append(strings.get(1));
                    for (int i = 2; i < strings.size(); i++) {
                        mainText.append("\n");
                        mainText.append(strings.get(i));
                    }
                }

                //put it in the right views
                TextView mainTextView = (TextView) getContentView().findViewById(R.id.mainTextView);
                mainTextView.setText(mainText);
            }
        }
        TextView titleView = (TextView) getContentView().findViewById(R.id.titleView);
        titleView.setText(title);

        /*
        if (!mIsTimelineView) {
            //show traceroute for all but user's current node
            Button tracerouteBtn = (Button) getContentView().findViewById(R.id.tracerouteBtn);
            tracerouteBtn.setVisibility(isUsersNode ? android.view.View.GONE : android.view.View.VISIBLE);
        }*/
    }
    
    /**
     * For some reason popupwindow doesn't have this.
     * @return the real height of the popup based on the layout.
     */
    public int getMeasuredHeight() {
        //update the layout for current data
        getContentView().measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
        return getContentView().getMeasuredHeight();
    }
}
