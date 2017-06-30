package com.peer1.internetmap.utils;

import android.app.Activity;
import android.view.View;

import com.spyhunter99.supertooltips.ToolTip;
import com.spyhunter99.supertooltips.ToolTipManager;
import com.spyhunter99.supertooltips.ToolTipView;
import com.spyhunter99.supertooltips.exception.ViewNotFoundRuntimeException;

/**
 * Created by shayla on 2017-06-27.
 */

public class CustomTooltipManager extends ToolTipManager {

    private boolean isShowingTooltip;

    public boolean isShowingTooltip() {
        return isShowingTooltip;
    }

    // No longer used, but keeping around for later, allows us to get a callback when the
    // tooltip view is clicked
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

    @Override
    public void showToolTip(final ToolTip tip, final View view) {
        super.showToolTip(tip, view);
        active.setClickable(false);
        isShowingTooltip = true;
    }

    @Override
    public void closeActiveTooltip() {
        super.closeActiveTooltip();
        isShowingTooltip = false;
    }

    protected InteractionListener listener;
    public void setInteractionListener(InteractionListener listener) {
        this.listener = listener;
    }


}
