package com.peer1.internetmap;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;


public class SearchPopup extends PopupWindow{
    private static String TAG = "SearchPopup";
    private MapControllerWrapper mController;
    
    /**
     * SearchNode: a lightweight wrapper for nodewrapper
     * @author chani
     * 
     * This provides lazy-loading of node data, and the required interface for ArrayAdapter use.
     *
     */
    private class SearchNode {
        public final int index;
        private NodeWrapper node;
        
        SearchNode(int index) {
            this.index = index;
        }
        
        //returns a display string for ArrayAdapter
        public String toString() {
            //load the node, if needed
            if (node == null) {
                node = mController.nodeAtIndex(index);
                if (node == null) { //can't happen. I hope.
                    Log.d(TAG, String.format("BUG!!! no such index %d", index));
                    return "";
                }
            }
            
            //display: ASN - Description
            return String.format("%s - %s", node.asn, node.friendlyDescription);
        }
    }

    public SearchPopup(Context context, MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        mController = controller;
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setOutsideTouchable(true); //make touching outside dismiss the popup
        setFocusable(true); //make clicks work

        final ListView listView = (ListView) getContentView().findViewById(R.id.searchResultsView);
        
        int numNodes = mController.nodeCount();
        //initial search results: use all the nodes!
        SearchNode[] nodes = new SearchNode[numNodes];
        for (int i = 0; i < numNodes; i++) {
            nodes[i] = new SearchNode(i);
        }
        Log.d(TAG, String.format("loaded %d nodes", numNodes));
        
        final ArrayAdapter<SearchNode> adapter = new ArrayAdapter<SearchNode>(context, android.R.layout.simple_list_item_1,
                android.R.id.text1, nodes);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                //TODO
                Log.d(TAG, "click!");
            }
        });
    }


}
