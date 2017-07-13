package com.peer1.internetmap.utils;

import android.app.Activity;
import android.view.View;

import com.spyhunter99.supertooltips.ToolTip;
import com.spyhunter99.supertooltips.ToolTipManager;
import com.spyhunter99.supertooltips.ToolTipView;

/**
 * ToolTipManager used to show "Help" tooltips
 * <p>
 * Wrapper around {@linkplain com.spyhunter99.supertooltips.ToolTipManager ToolTipManager}, allowing
 * us to add behaviour to expose if a tooltip is currently being shown or not.
 */
public class CustomTooltipManager extends ToolTipManager {

    private boolean isShowingTooltip;

    /**
     * @return True if a ToolTip is currently being shown to the user
     */
    public boolean isShowingTooltip() {
        return isShowingTooltip;
    }

    /**
     * Exposed ToolTipView interactions
     * Note, not currently used, but left for future use.
     */
    public interface InteractionListener {
        void onTooltipViewClicked(ToolTipView toolTipView);
    }

    protected InteractionListener listener;
    public void setInteractionListener(InteractionListener listener) {
        this.listener = listener;
    }

    public CustomTooltipManager(Activity act) {
        super(act);
    }

    public CustomTooltipManager(Activity act, CloseBehavior behavior, SameItemOpenBehavior sameItemOpenBehavior) {
        super(act, behavior, sameItemOpenBehavior);
    }

    //=====================================================================
    // Overridden methods
    //=====================================================================
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
}
