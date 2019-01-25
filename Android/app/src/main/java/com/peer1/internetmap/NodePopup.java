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
    private LayoutInflater inflater;

    private boolean showTraceroute = true;
    private boolean showPing = false;

    // Traceroute properties
    // todo could some of this be refactored into TracerouteUtil?
    private TracerouteUtil tracerouteUtil = TracerouteUtil.getInstance();
    private View traceview;
    private TextView traceTimerTextView;
    private long startTime;
    private Timer traceTimer;
    private LinearLayout traceListLayout;
    private int ipHops, asnHops;
    private int lastASNIndex = -1;
    private String currentElaspedTime;
    private ArrayList<Pair<Integer, ProbeWrapper>> unprocessedHops = new ArrayList<>();
    private ArrayList<NodeWrapper> asnHopNodeWrappers = new ArrayList<>();
    private boolean isProccessingHop = false;
    private NodeWrapper traceDestinationNode;

    public NodePopup(Context context, MapControllerWrapper mapController, View view, boolean isTimelineView, boolean isSimulated) {
        super(view);
        this.ctx = context;
        this.inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        this.mapController = mapController;
        this.isTimelineView = isTimelineView;
        this.isSimulated = isSimulated;
    }

//    public NodePopup(Context context, MapControllerWrapper mapController, View view, boolean isTimelineView, boolean isSimulated) {
//        super(view);
//        this.ctx = context;
//        this.inflater = (LayoutInflater)ctx.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
//        this.mapController = mapController;
//        this.isTimelineView = isTimelineView;
//        this.isSimulated = isSimulated;
//    }

    @Override
    public void dismiss() {
        resetTraceroute();
        nodeWrapper = null;
        super.dismiss();
    }

    //=======================================================================
    // Set Node info
    //=======================================================================
    public void setNode(NodeWrapper node) {
        setNode(node, false);
    }

    public void setNode(NodeWrapper node, boolean isUsersNode) {
        // If for some reason we are calling setNode on the same index, stop.
        if (nodeWrapper != null && nodeWrapper.index == node.index) {
            return;
        }

        nodeWrapper = node;
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
            // Show traceroute for all but user's current node
            showTraceroute = !isUsersNode;
        }

        if (showTraceroute) {
            resetTraceroute();
            Button tracerouteBtn = getContentView().findViewById(R.id.tracerouteBtn);
            tracerouteBtn.setVisibility(isUsersNode ? android.view.View.GONE : android.view.View.VISIBLE);
            tracerouteBtn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    startTraceroute();
                }
            });
        }

        if (showPing) {

        }
    }

    public void setPingNode(NodeWrapper node) {
        showTraceroute = false;
        showPing = true;
        setNode(node);
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

    //=======================================================================
    // Ping functionality
    //=======================================================================
    private void resetPing() {

    }

    private void startPing() {

    }

    private void stopPing() {

    }

    //=======================================================================
    // Traceroute functionality
    //=======================================================================
    private void resetTraceroute() {
        stopTraceroute();

        // Reset the traceroute UI
        View view = getContentView();
        traceview = view.findViewById(R.id.traceroute_details);
        if (traceview == null) {
            return;
        }

        TextView asnHopsText = (TextView) getContentView().findViewById(R.id.trace_asn_hops);
        TextView ipHops = (TextView) getContentView().findViewById(R.id.trace_ip_hops);
        traceTimerTextView = (TextView)view.findViewById(R.id.trace_time);
        traceListLayout = (LinearLayout)view.findViewById(R.id.trace_list_layout);
        traceDestinationNode = null;

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

    private void stopTraceroute() {
        // Stop any trace if it is running
        stopTraceTimer();
        tracerouteUtil.removeListener();
        tracerouteUtil.stopTrace();
    }

    private void startTraceroute() {
        if (tracerouteUtil.isRunning()) {
            tracerouteUtil.stopTrace();
            AppUtils.showError(App.getAppContext(), App.getAppContext().getString(R.string.tracerouteAlreadyRunning));
            return;
        }

        // Shouldn't have to reset these, but do it for clarity.
        ipHops = 0;
        asnHops = 0;
        lastASNIndex = -1;
        unprocessedHops = new ArrayList<>();
        asnHopNodeWrappers = new ArrayList<>();
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

        // Get the starting ASN and run trace
        addTraceText("Determining current ASN");
        CommonClient.getInstance().getUserASN(new CommonCallback<ASN>() {
            @Override
            public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                NodeWrapper node = mapController.nodeByAsn(response.body().getASNString());
                if (node != null) {
                    // Add our current asn as the first asn "hop"
                    asnHopNodeWrappers.add(node);
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

    /**
     * Cannot re-use Java Timers or TimerTasks
     */
    private void startTraceTimer() {
        stopTraceTimer();
        startTime = System.currentTimeMillis();
        traceTimer = new Timer();
        traceTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                traceview.post(new Runnable() {
                    @Override
                    public void run() {
                        long nowTime = System.currentTimeMillis();
                        long elapsed = nowTime - startTime;
                        currentElaspedTime = String.valueOf(elapsed);
                        traceTimerTextView.setText(currentElaspedTime);
                    }
                });
            }
        }, 0, 1);
    }

    private void stopTraceTimer() {
        try {
            traceTimer.cancel();
            traceTimer = null;
        } catch (Exception e) {
            // Will fail if not scheduled. Catch quietly, not a real issue.
        }
    }

    private void runTracerouteToSelectedNode() {
        if (!this.isShowing()) {
            // Popup no longer showing. User may have dismissed before ASN IP was determined. Abort!
            return;
        }

        // If lastSearchIP is set then run tracroute to lastSearchIP.
        // else
        //      get target selected asn node
        //      get the ips for the selected ASN node
        //      select random ip from ip list as destination IP
        //      run trace to destination IP

        // TODO get lastSearchIP?

        int targetNodeIndex = mapController.targetNodeIndex();
        traceDestinationNode = mapController.nodeAtIndex(targetNodeIndex);

        if (traceDestinationNode.asn == null) {
            addTraceText("Failed to resolve ASN location");
        } else {
            addTraceText("Fetching selected ASN location");
            CommonClient.getInstance().getApi().getIPsFromASN(traceDestinationNode.asn).enqueue(new CommonCallback<ASNIPs>() {
                @Override
                public void onRequestResponse(Call<ASNIPs> call, Response<ASNIPs> response) {
                    runTracerouteToIp(response.body().getIp());
                }

                @Override
                public void onRequestFailure(Call<ASNIPs> call, Throwable t) {
                    addTraceText("Failed to resolve ASN location");
                }
            });
        }
    }

    private void runTracerouteToIp(String destinationIP) {
        if (!this.isShowing()) {
            // Popup no longer showing. User may have dismissed before ASN IP was determined. Abort!
            return;
        } else if (TracerouteUtil.isInvalidOrPrivate(destinationIP)) {
            addTraceText("Cannot run traceroute, IP is reserved.");
            return;
        }
        else if (destinationIP.isEmpty()) {
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
            public void onTraceAlreadyRunning() {
                // This shouldn't happen as NodePopup checks isRunning before starting a new trace.
            }

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

        tracerouteUtil.startTrace(destinationIP);
    }

    /**
     * Currently queueing up all "hops" as they are discovered.
     * processNextHop will pop off the next item in the queue and process it.
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

        // Note: (null, null) indicates a final traceroute timeout.
        if (ttl == null) {
            addTraceText("Traceroute complete with as many hops as we could contact.");
            addFinalHopToDestination();
            isProccessingHop = false;
            return;
        } else if (hopProbe == null) {
            addTTLResult(ttl, "* * * Hop did not reply or timed out");
            isProccessingHop = false;
            processNextHop();
            return;
        }

        // Check to see if we have jumped an ASN. Wait to print out TTL result until we have the ASN.
        CommonClient.getInstance().getApi().getASNFromIP(hopProbe.fromAddress).enqueue(new CommonCallback<ASN>() {
            @Override
            public void onRequestResponse(Call<ASN> call, Response<ASN> response) {
                String asn = response.body().getASNString();
                NodeWrapper asnNode = (asn != null) ? mapController.nodeByAsn(asn) : null;
                boolean hasHoppedASN = (asnNode != null) && (lastASNIndex != asnNode.index);

                // Add node as an IP hop
                incrementIPHop();
                addTTLResult(ttl, hopProbe, asn);

                if (hasHoppedASN) {
                    lastASNIndex = asnNode.index;
                    asnHopNodeWrappers.add(asnNode);
                    incrementASNHop();
                    displayHops(asnHopNodeWrappers);
                }

                isProccessingHop = false;
                processNextHop();
            }

            @Override
            public void onRequestFailure(Call<ASN> call, Throwable t) {
                // TODO what to do if failed to get ASN?
                isProccessingHop = false;
                processNextHop();
                Timber.e("getASNFromIP failed");
            }
        });
    }

    private void displayHops(ArrayList<NodeWrapper> hops) {
        if (!this.isShowing()) {
            return;
        }

        // Only draw if we can at least make one line.
        if (hops.size() < 2) {
            return;
        }

        NodeWrapper[] mergedHops = hops.toArray(new NodeWrapper[hops.size()]);
        mapController.highlightRoute(mergedHops, mergedHops.length);
    }

    private void addTraceText(String text) {
        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        nextItemView.setText(text);
        traceListLayout.addView(nextItemView);
    }

    private void addTTLResult(int ttl, String text) {
        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        String result = String.valueOf(ttl) + ". " + text; // According to forums, without conditionals, this performs the same as StringBuilder.
        nextItemView.setText(result);
        traceListLayout.addView(nextItemView);
    }

    private void addTTLResult(int ttl, ProbeWrapper probe, String asn) {
        if (probe == null) {
            // TODO handle this error case
            return;
        }

        TextView nextItemView = (TextView)inflater.inflate(R.layout.view_tracerout_list_item, null);
        nextItemView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        StringBuilder result = new StringBuilder(100).append(ttl).append(". ").append(probe.fromAddress);

        if (probe.elapsedMs != 0) {
            result.append(String.format(" (%.2fms) ", probe.elapsedMs));
        }

        if (asn != null) {
            result.append(" (ASN").append(asn).append(") ");
        } else {
            result.append(" (Unknown ASN) ");
        }

        nextItemView.setText(result.toString());
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

    private void addFinalHopToDestination() {
        // Add final hop
        if (traceDestinationNode != null && lastASNIndex != traceDestinationNode.index) {
            lastASNIndex = traceDestinationNode.index;
            asnHopNodeWrappers.add(traceDestinationNode);
            incrementASNHop();
            displayHops(asnHopNodeWrappers);
        }
    }
}
