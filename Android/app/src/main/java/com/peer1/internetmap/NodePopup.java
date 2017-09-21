package com.peer1.internetmap;

import android.content.Context;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.PopupWindow;
import android.widget.TextView;

import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.network.common.CommonCallback;
import com.peer1.internetmap.network.common.CommonClient;
import com.peer1.internetmap.utils.AppUtils;
import com.peer1.internetmap.utils.TracerouteUtil;

import org.json.JSONException;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;
import java.util.TreeMap;

import retrofit2.Call;
import retrofit2.Response;

/**
 * Popup shown when an AS node is selected in a visualization
 *
 * TODO look into moving out of PopupWindow into a Fragment
 */
public class NodePopup extends PopupWindow {
    private static String TAG = "NodePopup";
    private Context ctx;
    private boolean isTimelineView;
    private boolean isSimulated;

    // Traceroute
    private View traceview;
    private TextView traceTimerTextView;
    private long startTime;
    private Timer traceTimer;
    //private ListView traceHopList;
    //private ArrayAdapter<String> traceListAdapter;
    private ArrayList<String> traceListStrings;
    private LinearLayout traceListLayout;
    private int asnHops;

    private MapControllerWrapper mapController;
    
    public NodePopup(Context context, MapControllerWrapper mapController, View view, boolean isTimelineView, boolean isSimulated) {
        super(view);
        this.ctx = context;
        this.mapController = mapController;
        this.isTimelineView = isTimelineView;
        this.isSimulated = isSimulated;

        DisplayMetrics displayMetrics = new DisplayMetrics();
    }

    public void setNode(NodeWrapper node) {
        setNode(node, false);
    }

    public void setNode(NodeWrapper node, boolean isUsersNode) {
        //set up content
        String title;
        if (isSimulated) {
            title = ctx.getString(R.string.simulated);
        } else {
            ArrayList<String> strings = new ArrayList<String>(4);
            if (isUsersNode && !isTimelineView) {
                strings.add(ctx.getString(R.string.youarehere));
            }
            String desc = node.friendlyDescription();
            if (!desc.isEmpty()) {
                strings.add(desc);
            }
            strings.add("AS" + node.asn);
            if (!isTimelineView) {
                if (!node.typeString.isEmpty()) {
                    strings.add(node.typeString);
                }
                //FIXME show # connections only on tablets..?
                if (node.numberOfConnections == 1) {
                    strings.add(ctx.getString(R.string.oneconnection));
                } else {
                    //<num> connections
                    strings.add(String.format(ctx.getString(R.string.nconnections), node.numberOfConnections));
                }
            }

            //split into title/rest
            title = strings.get(0);
            if (!isTimelineView) {
                StringBuilder mainText = new StringBuilder();
                if (strings.size() <= 1) {
                    //default text
                    mainText.append(ctx.getString(R.string.nomoredata));
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


        if (!isTimelineView) {
            //show traceroute for all but user's current node
            Button tracerouteBtn = (Button) getContentView().findViewById(R.id.tracerouteBtn);
            tracerouteBtn.setVisibility(isUsersNode ? android.view.View.GONE : android.view.View.VISIBLE);
            tracerouteBtn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    showTraceview();
                    runTraceroute();
                }
            });
        }
    }

    private void showTraceview() {
        View view = getContentView();
        traceview = view.findViewById(R.id.traceroute_details);
        traceTimerTextView = (TextView)view.findViewById(R.id.trace_time);
        //traceHopList = (ListView)view.findViewById(R.id.trace_list_view);
        traceListLayout = (LinearLayout)view.findViewById(R.id.trace_list_layout);

        View nodeDetails = getContentView().findViewById(R.id.contentLayout);
        traceview.setVisibility(View.VISIBLE);
        nodeDetails.setVisibility(View.GONE);

        traceListStrings = new ArrayList<>();

        //traceListAdapter = new ArrayAdapter<>(ctx, R.layout.view_tracerout_list_item, traceListStrings);
        //traceHopList.setAdapter(traceListAdapter);

        // Reposition map so that we can see it during the traceroute
        boolean isSmallScreen = AppUtils.isSmallScreen(ctx);
        mapController.resetZoomAndRotationAnimated(isSmallScreen);
        if (isSmallScreen) {
            mapController.translateYAnimated(0.4f, 1);
        }
    }

    private int nextItem;
    private void simulateListPopulation() {

        final ArrayList<String> fullList = new ArrayList<>();
        fullList.add("1. 10.1.1.1");
        fullList.add("2. 64.0.0.10");
        fullList.add("3. 120.13.33.323");
        fullList.add("4. 194.4.7.22");
        fullList.add("5. 194.4.7.22");
        fullList.add("6. 194.4.7.22");
        fullList.add("7. 194.4.7.22");
        fullList.add("8. 194.4.7.22");
        fullList.add("9. 194.4.7.22");
        fullList.add("10. 194.4.7.22");
        fullList.add("11. 194.4.7.22");
        fullList.add("12. 194.4.7.22");
        fullList.add("13. 194.4.7.22");
        fullList.add("14. 194.4.7.22");
        fullList.add("Complete");

        final Timer listPopTimer = new Timer();
        nextItem = 0;

        final LayoutInflater inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        listPopTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                traceview.post(new Runnable() {
                    @Override
                    public void run() {

                        if (nextItem < fullList.size()) {
                            TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
                            nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
                            nextItemView.setText(fullList.get(nextItem));
                            traceListLayout.addView(nextItemView);

                            //traceListStrings.add(fullList.get(nextItem));
                            //traceListAdapter.notifyDataSetChanged();
                            nextItem++;
                        } else {
                            stopTimer();
                            listPopTimer.cancel();
                        }
                    }
                });
            }
        }, 0, 500);
    }

    private void startTimer() {
        traceTimer = new Timer();
        startTime = System.currentTimeMillis();
        traceTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                traceview.post(new Runnable() {
                    @Override
                    public void run() {
                        traceTimerTextView.setText(getElapsedMs());
                    }
                });
            }
        }, 0, 1);
    }

    private void stopTimer() {
        traceTimer.cancel();
    }

    // Returns the combined string for the stopwatch, counting in tenths of seconds.
    public String getElapsedMs() {
        long nowTime = System.currentTimeMillis();
        long elapsed = nowTime - startTime;
        return String.valueOf(elapsed);
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

    public void runTraceroute() {

        asnHops = 0;

        startTimer();
        //simulateListPopulation();

//        boolean isConnected = haveConnectivity();
//
//        if (!isConnected) {
//            return;
//        }

        final TreeMap<String, String> ipASNLookup = new TreeMap<>();

        TracerouteUtil tracerouteUtil = new TracerouteUtil(mapController);
        tracerouteUtil.setListener(new TracerouteUtil.Listener() {
            @Override
            public void onHopFound(final int ttl, final String ip) {



                // Convert ip to asn.
                CommonClient.getInstance().getApi().getASNFromIP(ip).enqueue(new CommonCallback<ASN>() {
                    @Override
                    public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                        // TODO may need to call next TTL here to ensure order...

                        ipASNLookup.put(ip, response.body().getASNString());

                        // TODO determine if we have hopped ASNs

                        // Add hop text to list
                        addTraceHopToUI(ttl, ip, false);

                        // Update map
                        displayHops(ipASNLookup);
                    }

                    @Override
                    public void onRequestFailure(Call<ASN> call, Throwable t) {
//                        progress.setVisibility(View.INVISIBLE);
//                        searchIcon.setVisibility(View.VISIBLE);
//                        mHandler.removeCallbacks(backupTimer);
//
//                        String message = getString(R.string.asnAssociationFail);
//                        showError(message);
                        //Timber.d(message);
                    }
                });
            }

            @Override
            public void onTimeout(int ttl) {

            }
        });

        // TODO get currentASN
        tracerouteUtil.startTrace();
    }

    public void displayHops(TreeMap<String, String> hops) {


        // 



//        NSMutableArray* mergedAsnHops = [NSMutableArray new];
//
//        __block NSString* lastAsn = nil;
//        __block NSInteger lastIndex = -1;
//
//        // Put our ASN at the start of the list, just in case
//        NodeWrapper* us = [self.controller nodeByASN:self.cachedCurrentASN];
//        if(us) {
//        [mergedAsnHops addObject:us];
//            lastAsn = self.cachedCurrentASN;
//        }
//
//    [ips enumerateObjectsUsingBlock:^(NSString* ip, NSUInteger idx, BOOL *stop) {
//            NSString* asn = self.tracerouteASNs[ip];
//            if(asn && ![asn isEqual:[NSNull null]] && ![asn isEqualToString:lastAsn])  {
//                lastAsn = asn;
//                NodeWrapper* node = [self.controller nodeByASN:asn];
//                if(node) {
//                    lastIndex = node.index;
//                [mergedAsnHops addObject:node];
//                }
//            }
//        }];
//
//        if(destNode && (lastIndex != destNode.index)) {
//        [mergedAsnHops addObject:destNode];
//        }
//
//        if ([mergedAsnHops count] >= 2) {
//        [self.controller highlightRoute:mergedAsnHops];
//        }

    }

    private void addTraceHopToUI(int ttl, String hopText, boolean isASNHop) {
        final LayoutInflater inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        // Add line in list
        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        nextItemView.setText(String.format("%d. %s", ttl, hopText));
        traceListLayout.addView(nextItemView);

        // Update ASN hops
        if (isASNHop) {
            asnHops = asnHops+1;
            TextView asnHopsText = (TextView)getContentView().findViewById(R.id.trace_asn_hops);
            asnHopsText.setText(String.format("%d", asnHops));
        }
    }

}
