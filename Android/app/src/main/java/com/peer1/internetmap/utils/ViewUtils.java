package com.peer1.internetmap.utils;

import android.view.View;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;

/**
 * Created by shayla on 2017-06-28.
 */

public class ViewUtils {

    public static void fadeViewOut(final View view, long duration, final Animation.AnimationListener listener) {
        // setFillAfter was causing issues when attempting to re-show the view in question.
        // Instead, we set the view visibility before and after the fade animation.
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
