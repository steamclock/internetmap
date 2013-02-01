package com.peer1.internetmap;

import java.util.ArrayList;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;


public class SearchPopup extends PopupWindow{
    private static String TAG = "SearchPopup";
    private MapControllerWrapper mController;
    private NodeAdapter.NodeFilter mFilter;
    private ArrayList<SearchNode> mAllNodes;
    
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
            return String.format("%s - %s", node.asn, node.friendlyDescription());
        }
    }
    
    /**
     * An arrayadapter that can use and filter SearchNodes
     * @author chani
     *
     */
    private class NodeAdapter extends ArrayAdapter<SearchNode> {
        private ArrayList<SearchNode> mFilteredNodes;
        /**
         * Filters the list of search results.
         * @author chani
         *
         */
        public class NodeFilter extends Filter {
            @Override
            protected FilterResults performFiltering(CharSequence constraint) {
                //TODO actually filter
                FilterResults results = new FilterResults();
                if (constraint.length() <= 0) {
                    //default, full list
                    results.count = mAllNodes.size();
                    results.values = mAllNodes;
                } else {
                    //fake it
                    ArrayList<SearchNode> nodes = new ArrayList<SearchNode>(1);
                    nodes.add(mAllNodes.get(1));
                    results.values = nodes;
                    results.count = 1;
                }
                return results;
            }
            
            @SuppressWarnings("unchecked")
            @Override
            protected void publishResults(CharSequence constraint,
                    FilterResults results) {
                mFilteredNodes = (ArrayList<SearchNode>)results.values;
                notifyDataSetChanged();
            }
        }
        
        public NodeAdapter(Context context, int resource, int textViewResourceId) {
            super(context, resource, textViewResourceId);
            mFilteredNodes = mAllNodes;
            mFilter = new NodeFilter();
        }
        
        @Override
        public Filter getFilter(){
            return mFilter;
        }
        
        @Override
        public int getCount() {
            return mFilteredNodes.size();
        }
        @Override
        public SearchNode getItem(int position) {
            return mFilteredNodes.get(position);
        }
        @Override
        public int getPosition(SearchNode item) {
            return mFilteredNodes.indexOf(item);
        }
        @Override
        //note: this is undocumented and I have no idea what it's for
        public long getItemId(int position) {
            return position;
        }
    }

    public SearchPopup(Context context, MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        mController = controller;
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setOutsideTouchable(true); //make touching outside dismiss the popup
        setFocusable(true); //make clicks work

        //set up the results list
        int numNodes = mController.nodeCount();
        //initial search results: use all the nodes!
        mAllNodes = new ArrayList<SearchNode>(numNodes);
        for (int i = 0; i < numNodes; i++) {
            mAllNodes.add(new SearchNode(i));
        }
        Log.d(TAG, String.format("loaded %d nodes", numNodes));
        
        final NodeAdapter adapter = new NodeAdapter(context, android.R.layout.simple_list_item_1,
                android.R.id.text1);
        final ListView listView = (ListView) getContentView().findViewById(R.id.searchResultsView);
        listView.setAdapter(adapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                //TODO
                Log.d(TAG, "click!");
            }
        });
        
        //set up the input field
        EditText input = (EditText) getContentView().findViewById(R.id.searchEdit);
        input.addTextChangedListener(new TextWatcher(){
            public void afterTextChanged(Editable s) {
                String filter = s.toString();
                Log.d(TAG, filter);
                mFilter.filter(filter);
            }
            //unneeded abstract stuff
            public void beforeTextChanged(CharSequence arg0, int arg1, int arg2, int arg3) {}
            public void onTextChanged(CharSequence arg0, int arg1, int arg2, int arg3) {}
        });
    }

}
