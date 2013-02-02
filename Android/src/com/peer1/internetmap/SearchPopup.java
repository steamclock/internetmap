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
     * This the required interface for ArrayAdapter use and filtering.
     *
     */
    private class SearchNode {
        private NodeWrapper mNode;
        
        SearchNode(NodeWrapper node) {
            mNode = node;
        }
        
        //returns a display string for ArrayAdapter
        public String toString() {
            //display: ASN - Description
            return String.format("%s - %s", mNode.asn, mNode.friendlyDescription());
        }
        
        //return true if the node matches the search filter
        public boolean matches(CharSequence filter) {
            return mNode.asn.contains(filter) || mNode.rawTextDescription.contains(filter);
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
                FilterResults results = new FilterResults();
                if (constraint.length() <= 0) {
                    //default, full list
                    results.count = mAllNodes.size();
                    results.values = mAllNodes;
                    Log.d(TAG, "default nodes");
                } else {
                    //filter it
                    Log.d(TAG, "filtering...");
                    ArrayList<SearchNode> nodes = new ArrayList<SearchNode>();
                    //TODO use java style iterators
                    for (int i=0; i<mAllNodes.size(); i++) {
                        if (mAllNodes.get(i).matches(constraint)) {
                            nodes.add(mAllNodes.get(i));
                        }
                    }
                    Log.d(TAG, "filtered!");
                    results.values = nodes;
                    results.count = nodes.size();
                }
                return results;
            }
            
            @SuppressWarnings("unchecked")
            @Override
            protected void publishResults(CharSequence constraint,
                    FilterResults results) {
                mFilteredNodes = (ArrayList<SearchNode>)results.values;
                Log.d(TAG, String.format("matched %d nodes", results.count));
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
        NodeWrapper[] rawNodes = mController.allNodes();
        Log.d(TAG, String.format("loaded %d nodes", rawNodes.length));
        
        //initial search results: use all the nodes!
        mAllNodes = new ArrayList<SearchNode>(rawNodes.length);
        for (int i = 0; i < rawNodes.length; i++) {
            mAllNodes.add(new SearchNode(rawNodes[i]));
        }
        Log.d(TAG, String.format("converted %d nodes", mAllNodes.size()));
        
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
