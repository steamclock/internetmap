package com.peer1.internetmap.utils;

import android.view.View;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;

public class ViewUtils {
    /**
     * Runs an AlphaAnimation on the given view.
     * Note, onAnimationEnd the view visibility will be set to GONE.
     * setFillAfter was causing issues when attempting to re-show the view in question, so instead
     * we set the visibility to GONE after the animation is complete.
     * @param view The view to animate
     * @param duration Animation duration in milliseconds
     * @param listener AnimationListener if desired; optional, can be null.
     */
    public static void fadeViewOut(final View view, long duration, final Animation.AnimationListener listener) {
        view.setVisibility(View.VISIBLE);
        AlphaAnimation alpha = new AlphaAnimation(1.0f, 0.0f);
        alpha.setDuration(duration);
        alpha.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
                if (listener != null) listener.onAnimationStart(animation);
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                view.setVisibility(View.GONE);
                if (listener != null) listener.onAnimationEnd(animation);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
                if (listener != null) listener.onAnimationRepeat(animation);
            }
        });

        view.startAnimation(alpha);
    }
}
