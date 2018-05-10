package com.peer1.internetmap;

import android.content.Context;
import android.os.Handler;
import android.support.v4.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.PopupWindow;
import android.widget.TextView;

import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.models.ASNIPs;
import com.peer1.internetmap.network.common.CommonCallback;
import com.peer1.internetmap.network.common.CommonClient;
import com.peer1.internetmap.utils.AppUtils;
import com.peer1.internetmap.utils.TracerouteUtil;

import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

import retrofit2.Call;
import retrofit2.Response;
import timber.log.Timber;

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
    private MapControllerWrapper mapController;
    private NodeWrapper nodeWrapper;

    // Traceroute
    private TracerouteUtil tracerouteUtil;
    private View traceview;
    private TextView traceTimerTextView;
    private long startTime;
    private Timer traceTimer;
    private LinearLayout traceListLayout;
    private int ipHops, asnHops;
    private int lastASNIndex = -1;
    private ArrayList<Pair<Integer, ProbeWrapper>> unprocessedHops = new ArrayList<>();
    private ArrayList<NodeWrapper> hopNodeWrappers = new ArrayList<>();
    private boolean isProccessingHop = false;

    public NodePopup(Context context, MapControllerWrapper mapController, View view, boolean isTimelineView, boolean isSimulated) {
        super(view);
        this.ctx = context;
        this.mapController = mapController;
        this.isTimelineView = isTimelineView;
        this.isSimulated = isSimulated;
    }

    @Override
    public void dismiss() {
        if (tracerouteUtil != null) {
            tracerouteUtil.stopTrace();
            tracerouteUtil = null;
        }

        nodeWrapper = null;
        super.dismiss();
    }

    public void setNode(NodeWrapper node) {
        setNode(node, false);
    }

    public void setNode(NodeWrapper node, boolean isUsersNode) {

        // If for some reason we are calling setNode on the same index, stop.
        if (nodeWrapper != null && nodeWrapper.index == node.index) {
            return;
        }

        nodeWrapper = node;
        resetTracerouteUI();

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

        // Reset traceroute view


        if (!isTimelineView) {
            //show traceroute for all but user's current node
            Button tracerouteBtn = (Button) getContentView().findViewById(R.id.tracerouteBtn);
            tracerouteBtn.setVisibility(isUsersNode ? android.view.View.GONE : android.view.View.VISIBLE);
            tracerouteBtn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    startTraceroute();
                }
            });
        }
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

    private void resetTracerouteUI() {
        // Reset the traceroute UI
        View view = getContentView();
        TextView asnHopsText = (TextView) getContentView().findViewById(R.id.trace_asn_hops);
        TextView ipHops = (TextView) getContentView().findViewById(R.id.trace_ip_hops);
        traceview = view.findViewById(R.id.traceroute_details);
        traceTimerTextView = (TextView)view.findViewById(R.id.trace_time);
        traceListLayout = (LinearLayout)view.findViewById(R.id.trace_list_layout);

        // Reset and hide traceroute details
        traceview.setVisibility(View.GONE);
        asnHopsText.setText("0");
        ipHops.setText("0");
        traceTimerTextView.setText("0");
        traceListLayout.removeAllViews();

        // Show node details
        View nodeDetails = getContentView().findViewById(R.id.contentLayout);
        nodeDetails.setVisibility(View.VISIBLE);

        view.invalidate();
    }

    /**
     *
     */
    private void startTraceroute() {
        // Shouldn't have to reset these, but do it for clarity.
        ipHops = 0;
        asnHops = 0;
        lastASNIndex = -1;
        tracerouteUtil = new TracerouteUtil(mapController);
        unprocessedHops = new ArrayList<>();
        hopNodeWrappers = new ArrayList<>();
        isProccessingHop = false;

        // Show the traceroute UI
        View view = getContentView();
        traceview = view.findViewById(R.id.traceroute_details);
        traceTimerTextView = (TextView)view.findViewById(R.id.trace_time);
        traceListLayout = (LinearLayout)view.findViewById(R.id.trace_list_layout);
        View nodeDetails = getContentView().findViewById(R.id.contentLayout);
        traceview.setVisibility(View.VISIBLE);
        nodeDetails.setVisibility(View.GONE);
        view.invalidate();

        // Reposition map so that we can see it during the traceroute
        boolean isSmallScreen = AppUtils.isSmallScreen(ctx);
        mapController.resetZoomAndRotationAnimated(isSmallScreen);
        if (isSmallScreen) {
            mapController.translateYAnimated(0.4f, 1);
        }

        mapController.clearHighlightLines();

        // Get the starting ASN and run trace
        addTraceText("Determining current ASN");
        CommonClient.getInstance().getUserASN(new CommonCallback<ASN>() {
            @Override
            public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                NodeWrapper node = mapController.nodeByAsn(response.body().getASNString());
                if (node != null) {
                    hopNodeWrappers.add(node);
                    lastASNIndex = node.index;
                }
                runTracerouteToSelectedNode();
            }

            @Override
            public void onRequestFailure(Call<ASN> call, Throwable t) {
                Timber.e("startTraceroute could not determine user ASN");
                runTracerouteToSelectedNode();
            }
        });
    }

    private void startTraceTimer() {
        traceTimer = new Timer();
        startTime = System.currentTimeMillis();
        traceTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                traceview.post(new Runnable() {
                    @Override
                    public void run() {
                        updateCurrentElaspedMs();
                    }
                });
            }
        }, 0, 1);
    }

    private void stopTraceTimer() {
        traceTimer.cancel();
    }

    // Returns the combined string for the stopwatch, counting in tenths of seconds.
    private String currentElaspedTime;
    private void updateCurrentElaspedMs() {
        long nowTime = System.currentTimeMillis();
        long elapsed = nowTime - startTime;
        currentElaspedTime = String.valueOf(elapsed);
        traceTimerTextView.setText(currentElaspedTime);
    }

    /**
     *
     */
    private void runTracerouteToSelectedNode() {
        // If lastSearchIP is set then run tracroute to lastSearchIP.
        // else
        //      get target selected asn node
        //      get the ips for the selected ASN node
        //      select random ip from ip list as destination IP
        //      run trace to destination IP

        // TODO get lastSearchIP

        int targetNodeIndex = mapController.targetNodeIndex();
        NodeWrapper node = mapController.nodeAtIndex(targetNodeIndex);

        if (node.asn == null) {
            // TODO couldntResolveIP error.
            addTraceText("Failed to resolve ASN location");
        } else {
            addTraceText("Fetching selected ASN location");
            CommonClient.getInstance().getApi().getIPsFromASN(node.asn).enqueue(new CommonCallback<ASNIPs>() {
                @Override
                public void onRequestResponse(Call<ASNIPs> call, Response<ASNIPs> response) {
                    runTracerouteToIp(response.body().getIp());
                }

                @Override
                public void onRequestFailure(Call<ASNIPs> call, Throwable t) {
                    // TODO couldntResolveIP error.
                    addTraceText("Failed to resolve ASN location");
                }
            });
        }
    }

    private void runTracerouteToIp(String destinationIP) {

        if (destinationIP == null || destinationIP.isEmpty()) {
            addTraceText("There was a problem determining the destination location");
            return;
        }

        addTraceText(String.format("Starting trace to %s", destinationIP));
        startTraceTimer();

        // Note, we are running the probes in an AsyncTask, make sure to run the results
        // on the main thread so that we can correctly update the UI.
        // TODO find a better way to handle thread interaction
        tracerouteUtil.setListener(new TracerouteUtil.Listener() {
            @Override
            public void onHopFound(final int ttl, final ProbeWrapper probeWrapper) {
                new Handler(ctx.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        Pair<Integer, ProbeWrapper> hop = new Pair<>(ttl, probeWrapper);
                        unprocessedHops.add(hop);
                        processNextHop();
                    }
                });
            }

            @Override
            public void onHopTimeout(final int ttl) {
                new Handler(ctx.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        Pair<Integer, ProbeWrapper> hop = new Pair<>(ttl, null);
                        unprocessedHops.add(hop);
                        processNextHop();
                    }
                });
            }

            @Override
            public void onComplete() {
                new Handler(ctx.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        stopTraceTimer();
                    }
                });
            }

            @Override
            public void onTraceTimeout() {
                new Handler(ctx.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        stopTraceTimer();
                        Pair<Integer, ProbeWrapper> hop = new Pair<>(null, null);
                        unprocessedHops.add(hop);
                        processNextHop();

                    }
                });
            }

            @Override
            public void onLoopDiscovered() {
                new Handler(ctx.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        stopTraceTimer();
                        Pair<Integer, ProbeWrapper> hop = new Pair<>(null, null);
                        unprocessedHops.add(hop);
                        processNextHop();
                    }
                });
            }
        });

        // TODO get currentASN
        tracerouteUtil.startTrace(destinationIP);
    }

    /**
     * TODO come up with better way to handle hop queue...? Having to keep track via isProccessingHop
     * is not ideal...
     * TODO synch around unprocessedHops array to avoid concurrent access
     */
    private void processNextHop() {

        if (isProccessingHop) {
            return;
        }

        if (unprocessedHops.size() == 0) {
            return;
        }

        isProccessingHop = true;

        Pair<Integer, ProbeWrapper> nextHop = unprocessedHops.remove(0);
        final Integer ttl = nextHop.first;
        final ProbeWrapper hopProbe = nextHop.second;

        // Add entry to result list and bump IP hop if necessary
        // Note: (null, null) indicates a full tracet timeout.
        if (ttl == null) {
            addTraceText("Traceroute complete with as many hops as we could contact.");
            isProccessingHop = false;
            processNextHop();
            return;
        } else if (hopProbe == null) {
            addTTLResult(ttl, "* * * Hop did not reply or timed out");
            isProccessingHop = false;
            processNextHop();
            return;
        }

        incrementIPHop();

        // Check to see if we have jumped an ASN
        CommonClient.getInstance().getApi().getASNFromIP(hopProbe.fromAddress).enqueue(new CommonCallback<ASN>() {
            @Override
            public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                String asn = response.body().getASNString();
                NodeWrapper node = null;
                boolean hasHoppedASN = false;

                if (asn != null) {
                    node = mapController.nodeByAsn(asn);
                }

                if (node != null) {
                    hopNodeWrappers.add(node);
                    hasHoppedASN = (lastASNIndex != node.index);
                    lastASNIndex = node.index;
                }

                if (hasHoppedASN) {
                    // Update map
                    incrementASNHop();
                    displayHops(hopNodeWrappers);
                }

                addTTLResult(ttl, hopProbe, asn);
                isProccessingHop = false;
                processNextHop();
            }

            @Override
            public void onRequestFailure(Call<ASN> call, Throwable t) {
                // TODO what to do if failed to get ASN?
                isProccessingHop = false;
                processNextHop();
                Timber.e("getASNFromIP FAILED YO");
            }
        });
    }

    private void displayHops(ArrayList<NodeWrapper> hops) {

        // If we are no longer running a trace, then do not display hops
        // Could happen if our request for IPtoASN comes back late.
        if (tracerouteUtil == null) {
            return;
        }

        // Only draw if we can at least make one line.
        if (hops.size() < 2) {
            return;
        }

        // Ew, make this better, maybe pass in cleaner data.
        NodeWrapper[] mergedHops = hops.toArray(new NodeWrapper[hops.size()]);

        mapController.highlightRoute(mergedHops, mergedHops.length);



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

    private void addTraceText(String text) {
        final LayoutInflater inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        nextItemView.setText(text);
        traceListLayout.addView(nextItemView);
    }

    private void addTTLResult(int ttl, String text) {
        final LayoutInflater inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        String result = String.format("%d. %s", ttl, text);
        nextItemView.setText(result);
        traceListLayout.addView(nextItemView);
    }

    private void addTTLResult(int ttl, ProbeWrapper probe, String asn) {
        if (probe == null) {
            // TODO handle this error case
            return;
        }

        final LayoutInflater inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        String result = String.format("%d. %s", ttl, probe.fromAddress);

        if (probe.elapsedMs != 0) {
            result += String.format(" (%.2fms) ", probe.elapsedMs);
        }

        if (asn != null) {
            result += String.format(" (ASN %s) ", asn);
        } else {
            result += " (Unknown ASN) ";
        }

        nextItemView.setText(result);
        traceListLayout.addView(nextItemView);
    }

    private void incrementASNHop() {
        asnHops = asnHops + 1;
        TextView asnHopsText = (TextView) getContentView().findViewById(R.id.trace_asn_hops);
        asnHopsText.setText(String.format("%d", asnHops));
    }

    private void incrementIPHop() {
        ipHops = ipHops + 1;
        TextView ipHops = (TextView) getContentView().findViewById(R.id.trace_ip_hops);
        ipHops.setText(String.format("%d", this.ipHops));
    }

}
