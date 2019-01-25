package com.peer1.internetmap;

import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.ArrayList;

public class PingUsAdapter extends RecyclerView.Adapter<PingUsAdapter.ItemViewHolder> {

    public interface Listener {
        void onClicked(String ipAddress);
    }

    private Listener listener;

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    private ArrayList<AdapterItem> items;

    private class AdapterItem {
        public String title;
        public String ipAddress;

        public AdapterItem(String title) {
            this.title = title;
            this.ipAddress = null;
        }

        public AdapterItem(String title, String ipAddress) {
            this.title = title;
            this.ipAddress = ipAddress;
        }
    }

    private ArrayList<AdapterItem> createItems() {
        ArrayList<AdapterItem> result = new ArrayList<>();
        result.add(new AdapterItem("Test"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Not real", "999.999.999.999"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        result.add(new AdapterItem("Google", "172.217.3.196"));
        return result;
    }

    public static class ItemViewHolder extends RecyclerView.ViewHolder {
        // each data item is just a string in this case
        public TextView titleText;
        public ItemViewHolder(TextView v) {
            super(v);
            titleText = v;
        }
    }

    public PingUsAdapter() {
        items = createItems();
    }

    @Override
    public ItemViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        // create a new view
        TextView v = (TextView) LayoutInflater.from(parent.getContext()).inflate(R.layout.view_simple_list_item, parent, false);
        ItemViewHolder vh = new ItemViewHolder(v);
        return vh;
    }

    @Override
    public void onBindViewHolder(ItemViewHolder holder, int position) {
        final AdapterItem item = items.get(position);
        holder.titleText.setText(item.title);

        if (item.ipAddress == null) {
            // title only
            // todo make bold
            holder.titleText.setOnClickListener(null);
        } else {
            holder.titleText.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (listener != null) listener.onClicked(item.ipAddress);
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return (items == null) ? 0 : items.size();
    }
}