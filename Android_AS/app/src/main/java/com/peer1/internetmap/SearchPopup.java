package com.peer1.internetmap;

import java.util.ArrayList;
import java.util.regex.Pattern;

import junit.framework.Assert;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager.LayoutParams;
import android.view.inputmethod.EditorInfo;
import android.widget.*;
import android.widget.TextView.OnEditorActionListener;


public class SearchPopup extends PopupWindow{
    private static String TAG = "SearchPopup";
    private MapControllerWrapper mController;
    private NodeAdapter.NodeFilter mFilter;
    private ArrayList<SearchNode> mAllNodes;
    private Context mContext;

    /** required interface for arrayadapter items */
    public interface SearchItem {
        public String toString();
    }
    /**
     * SearchNode: a lightweight wrapper for nodewrapper
     * @author chani
     * 
     * This implements the required interface for ArrayAdapter use and filtering.
     *
     */
    public static class SearchNode implements SearchItem {
        public final NodeWrapper node;
        private final String nameLower, descLower;
        
        SearchNode(NodeWrapper node) {
            this.node = node;
            this.nameLower = this.node.asn.toLowerCase();
            this.descLower = this.node.rawTextDescription.toLowerCase();
        }
        
        //returns a display string for ArrayAdapter
        public String toString() {
            //display: ASN - Description
            return String.format("%s - %s", node.asn, node.friendlyDescription());
        }

        public boolean contains(String substring) {
            String lowerSearch = substring.toLowerCase();
            return this.nameLower.contains(lowerSearch) || this.descLower.contains(lowerSearch);
        }
        
        //return true if the node matches the search filter
        public boolean matches(Pattern pattern) {
            return pattern.matcher(node.asn).find() || pattern.matcher(node.rawTextDescription).find();
        }
    }
    
    /**
     * special 'find host' item
     */
    private class FindHostItem implements SearchItem {
        public final String host;
        
        FindHostItem(String host) {
            this.host = host;
        }
        
        public String toString() {
            return String.format(mContext.getString(R.string.findHost), host);
        }
    }
    
    /**
     * special 'your location' item
     */
    private class LocationItem implements SearchItem {
        public String toString() {
            return mContext.getString(R.string.yourLocation);
        }
    }

    private class SearchingItem implements SearchItem {
        public String toString() {
            return mContext.getString(R.string.searching);
        }
    }

    /**
     * An arrayadapter that can use and filter SearchNodes
     * @author chani
     *
     */
    private class NodeAdapter extends ArrayAdapter<SearchItem> {
        private ArrayList<? extends SearchItem> mFilteredNodes;

        @Override
        //highlight the first item, and give an icon to the 'your location' item.
        public View getView(int position, View convertView, ViewGroup parent) {
            TextView textView = (TextView) super.getView(position, convertView, parent);
            boolean isFirstItem = (position == 0);
            boolean isShowingYouAreHere = false;
            if (isFirstItem) {
                Assert.assertTrue(getCount() > 0);
                SearchItem item = getItem(0);
                isShowingYouAreHere = item.getClass() == LocationItem.class;
            }
            
            int color = isFirstItem ? mContext.getResources().getColor(R.color.orange) : Color.WHITE;
            Drawable img = isShowingYouAreHere ? mContext.getResources().getDrawable(R.drawable.youarehere_selected) : null;

            textView.setTextColor(color);
            textView.setCompoundDrawablesWithIntrinsicBounds(null, null, img, null);
            
            return textView;
        }

        public void showLoading() {
            mFilteredNodes.clear();

            SearchItem searchingItem = new SearchingItem();
            ArrayList<SearchItem> nodes = new ArrayList<SearchItem>();
            nodes.add(searchingItem);
            mFilteredNodes = nodes;
            notifyDataSetChanged();
        }

        /**
         * Filters the list of search results.
         * @author chani
         *
         */
        public class NodeFilter extends Filter {
            private boolean mIsFiltering = false;

            public boolean isFiltering() {
                return mIsFiltering;
            }

            private final LocationItem locationItem = new LocationItem();

            @Override
            protected FilterResults performFiltering(CharSequence constraint) {
                mIsFiltering = true;

                ArrayList<SearchItem> nodes = new ArrayList<SearchItem>();
                if (constraint.length() <= 0) {
                    //default, full list + location
                    nodes.add(locationItem);
                    nodes.addAll(mAllNodes);
                } else {
                    //filter it
                    Log.d(TAG, "filtering...");

                    // Old method, using RegEx - was too slow.
                    // Pattern pattern = Pattern.compile(Pattern.quote(constraint.toString()), Pattern.CASE_INSENSITIVE);

                    for (int i=0; i<mAllNodes.size(); i++) {

                        // Old method, using RegEx - was too slow.
                        // if (mAllNodes.get(i).matches(pattern))

                        if (mAllNodes.get(i).contains(constraint.toString())) {
                            nodes.add(mAllNodes.get(i));

                        }
                    }

                    //'find host' option?
                    //FIXME this can't be the best way to do contains()
                    if (nodes.isEmpty() || constraint.toString().contains(".")) {
                        FindHostItem item = new FindHostItem(constraint.toString());
                        nodes.add(0, item);
                    }
                }
                
                FilterResults results = new FilterResults();
                results.values = nodes;
                results.count = nodes.size();
                return results;
            }
            
            @SuppressWarnings("unchecked")
            @Override
            protected void publishResults(CharSequence constraint,
                    FilterResults results) {
                
                mIsFiltering = false;
                mFilteredNodes = (ArrayList<SearchItem>)results.values;
                Assert.assertNotNull(mFilteredNodes);
                Log.d(TAG, String.format("matched %d nodes", results.count));
                notifyDataSetChanged();
            }
        }
        
        public NodeAdapter(Context context, int resource, int textViewResourceId) {
            super(context, resource, textViewResourceId);
            mFilteredNodes = new ArrayList<SearchItem>();
            mFilter = new NodeFilter();
            mFilter.filter("");
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
        public SearchItem getItem(int position) {
            return mFilteredNodes.get(position);
        }
        @Override
        public int getPosition(SearchItem item) {
            return mFilteredNodes.indexOf(item);
        }
        @Override
        //note: this is undocumented and I have no idea what it's for
        public long getItemId(int position) {
            return position;
        }
    }

    public SearchPopup(final InternetMap context, MapControllerWrapper controller, View view) {
        super(view, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        mContext = context;
        mController = controller;
        setBackgroundDrawable(new ColorDrawable(context.getResources().getColor(R.color.translucentBlack)));
        setOutsideTouchable(true); //make touching outside dismiss the popup
        setFocusable(true); //make clicks work
        setSoftInputMode(LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE); //show keyboard
        
        mAllNodes = context.mAllSearchNodes;

        final NodeAdapter adapter = new NodeAdapter(context, android.R.layout.simple_list_item_1,
                android.R.id.text1);
        final ListView listView = (ListView) getContentView().findViewById(R.id.searchResultsView);
        listView.setAdapter(adapter);
        final EditText input = (EditText) getContentView().findViewById(R.id.searchEdit);

        //handle item clicks
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int position, long l) {
                // Disable click if we are in the middle of a filter
                if (mFilter.isFiltering()) {
                    return;
                }

                SearchItem item = adapter.getItem(position);
                if (item instanceof SearchNode) {
                    SearchNode snode = (SearchNode)item;
                    mController.updateTargetForIndex(snode.node.index);
                } else if (item instanceof LocationItem) {
                    context.youAreHereButtonPressed();
                } else { //FindHostItem
                    //the text in the item may be out of date, so, get the text out of the search input.
                    String host = input.getText().toString();
                    context.findHost(host);
                }
                SearchPopup.this.dismiss();
            }
        });
        
        //set up the input field
        input.addTextChangedListener(new TextWatcher(){
            public void afterTextChanged(final Editable s) {
                // Wait short time before firing off filter.
                searchTimeoutHandler.removeCallbacksAndMessages(null);
                searchTimeoutHandler.postDelayed(new Runnable() {
                    public void run() {
                        adapter.showLoading();
                        String filter = s.toString();
                        mFilter.filter(filter);
                    }
                }, 500);
            }
            //unneeded abstract stuff
            public void beforeTextChanged(CharSequence arg0, int arg1, int arg2, int arg3) {}
            public void onTextChanged(CharSequence arg0, int arg1, int arg2, int arg3) {}
        });
        input.setOnEditorActionListener(new OnEditorActionListener() {
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                boolean handled = false;
                if (actionId == EditorInfo.IME_ACTION_GO) {
                    listView.performItemClick(null, 0, 0);
                    handled = true;
                }
                return handled;
            }
        });
    }

    Handler searchTimeoutHandler = new Handler();
}
