package com.peer1.internetmap.utils;

import android.app.Activity;

import com.spyhunter99.supertooltips.ToolTipManager;
import com.spyhunter99.supertooltips.ToolTipView;

/**
 * Created by shayla on 2017-06-27.
 */

public class CustomTooltipManager extends ToolTipManager {

    public interface InteractionListener {
        void onTooltipViewClicked(ToolTipView toolTipView);
    }

    public CustomTooltipManager(Activity act) {
        super(act);
    }

    public CustomTooltipManager(Activity act, CloseBehavior behavior, SameItemOpenBehavior sameItemOpenBehavior) {
        super(act, behavior, sameItemOpenBehavior);
    }

    @Override
    public void onToolTipViewClicked(ToolTipView toolTipView) {
        super.onToolTipViewClicked(toolTipView);

        if (listener != null) {
            listener.onTooltipViewClicked(toolTipView);
        }
    }

    protected InteractionListener listener;
    public void setInteractionListener(InteractionListener listener) {
        this.listener = listener;
    }
}
