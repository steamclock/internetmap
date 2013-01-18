/*
 * Copyright (C) 2010 The Android Open Source Project
 * Copyright (C) 2013 Steamclock
 * 
 * Note: this file is based on ScaleGestureDetector.java from android
 * https://android.googlesource.com/platform/frameworks/base/+/48c7c6c19aaa1a17a870cb7c7b55712689662ea4/core/java/android/view/ScaleGestureDetector.java
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 */
package com.peer1.internetmap;

import android.content.Context;
import android.content.res.Resources;
import android.os.SystemClock;
import android.util.FloatMath;

/**
 * Detects 2-finger rotate transformation gestures using the supplied {@link MotionEvent}s.
 * The {@link OnRotateGestureListener} callback will notify users when a particular
 * gesture event has occurred.
 *
 * This class should only be used with {@link MotionEvent}s reported via touch.
 *
 * To use this class:
 * <ul>
 *  <li>Create an instance of the {@code RotateGestureDetector} for your
 *      {@link View}
 *  <li>In the {@link View#onTouchEvent(MotionEvent)} method ensure you call
 *          {@link #onTouchEvent(MotionEvent)}. The methods defined in your
 *          callback will be executed when the events occur.
 * </ul>
 */
public class RotateGestureDetector {
    private static final String TAG = "RotateGestureDetector";

    /**
     * The listener for receiving notifications when gestures occur.
     * If you want to listen for all the different gestures then implement
     * this interface. If you only want to listen for a subset it might
     * be easier to extend {@link SimpleOnRotateGestureListener}.
     *
     * An application will receive events in the following order:
     * <ul>
     *  <li>One {@link OnRotateGestureListener#onRotateBegin(RotateGestureDetector)}
     *  <li>Zero or more {@link OnRotateGestureListener#onRotate(RotateGestureDetector)}
     *  <li>One {@link OnRotateGestureListener#onRotateEnd(RotateGestureDetector)}
     * </ul>
     */
    public interface OnRotateGestureListener {
        /**
         * Responds to rotate events for a gesture in progress.
         * Reported by pointer motion.
         *
         * @param detector The detector reporting the event - use this to
         *          retrieve extended info about event state.
         * @return Whether or not the detector should consider this event
         *          as handled. If an event was not handled, the detector
         *          will continue to accumulate movement until an event is
         *          handled. This can be useful if an application, for example,
         *          only wants to update rotate factors if the change is
         *          greater than 0.01.
         */
        public boolean onRotate(RotateGestureDetector detector);

        /**
         * Responds to the beginning of a rotate gesture. Reported by
         * new pointers going down.
         *
         * @param detector The detector reporting the event - use this to
         *          retrieve extended info about event state.
         * @return Whether or not the detector should continue recognizing
         *          this gesture. For example, if a gesture is beginning
         *          with a focal point outside of a region where it makes
         *          sense, onRotateBegin() may return false to ignore the
         *          rest of the gesture.
         */
        public boolean onRotateBegin(RotateGestureDetector detector);

        /**
         * Responds to the end of a rotate gesture. Reported by existing
         * pointers going up.
         *
         * Once a rotate has ended, {@link RotateGestureDetector#getFocusX()}
         * and {@link RotateGestureDetector#getFocusY()} will return focal point
         * of the pointers remaining on the screen.
         *
         * @param detector The detector reporting the event - use this to
         *          retrieve extended info about event state.
         */
        public void onRotateEnd(RotateGestureDetector detector);
    }

    /**
     * A convenience class to extend when you only want to listen for a subset
     * of rotate-related events. This implements all methods in
     * {@link OnRotateGestureListener} but does nothing.
     * {@link OnRotateGestureListener#onRotate(RotateGestureDetector)} returns
     * {@code false} so that a subclass can retrieve the accumulated rotate
     * factor in an overridden onRotateEnd.
     * {@link OnRotateGestureListener#onRotateBegin(RotateGestureDetector)} returns
     * {@code true}.
     */
    public static class SimpleOnRotateGestureListener implements OnRotateGestureListener {

        public boolean onRotate(RotateGestureDetector detector) {
            return false;
        }

        public boolean onRotateBegin(RotateGestureDetector detector) {
            return true;
        }

        public void onRotateEnd(RotateGestureDetector detector) {
            // Intentionally empty
        }
    }

    private final Context mContext;
    private final OnRotateGestureListener mListener;

    private float mFocusX;
    private float mFocusY;

    private float mCurrSpan;
    private float mPrevSpan;
    private float mInitialSpan;
    private float mCurrSpanX;
    private float mCurrSpanY;
    private float mPrevSpanX;
    private float mPrevSpanY;
    private long mCurrTime;
    private long mPrevTime;
    private boolean mInProgress;
    private int mSpanSlop;
    private int mMinSpan;

    // Bounds for recently seen values
    private float mTouchUpper;
    private float mTouchLower;
    private float mTouchHistoryLastAccepted;
    private int mTouchHistoryDirection;
    private long mTouchHistoryLastAcceptedTime;
    private int mTouchMinMajor;

    private static final long TOUCH_STABILIZE_TIME = 128; // ms
    private static final int TOUCH_MIN_MAJOR = 48; // dp

    /**
     * Consistency verifier for debugging purposes.
     */
    private final InputEventConsistencyVerifier mInputEventConsistencyVerifier =
            InputEventConsistencyVerifier.isInstrumentationEnabled() ?
                    new InputEventConsistencyVerifier(this, 0) : null;

    public RotateGestureDetector(Context context, OnRotateGestureListener listener) {
        mContext = context;
        mListener = listener;
        mSpanSlop = ViewConfiguration.get(context).getScaledTouchSlop() * 2;

        final Resources res = context.getResources();
        mTouchMinMajor = res.getDimensionPixelSize(
                com.android.internal.R.dimen.config_minScalingTouchMajor);
        mMinSpan = res.getDimensionPixelSize(
                com.android.internal.R.dimen.config_minScalingSpan);
    }

    /**
     * The touchMajor/touchMinor elements of a MotionEvent can flutter/jitter on
     * some hardware/driver combos. Smooth it out to get kinder, gentler behavior.
     * @param ev MotionEvent to add to the ongoing history
     */
    private void addTouchHistory(MotionEvent ev) {
        final long currentTime = SystemClock.uptimeMillis();
        final int count = ev.getPointerCount();
        boolean accept = currentTime - mTouchHistoryLastAcceptedTime >= TOUCH_STABILIZE_TIME;
        float total = 0;
        int sampleCount = 0;
        for (int i = 0; i < count; i++) {
            final boolean hasLastAccepted = !Float.isNaN(mTouchHistoryLastAccepted);
            final int historySize = ev.getHistorySize();
            final int pointerSampleCount = historySize + 1;
            for (int h = 0; h < pointerSampleCount; h++) {
                float major;
                if (h < historySize) {
                    major = ev.getHistoricalTouchMajor(i, h);
                } else {
                    major = ev.getTouchMajor(i);
                }
                if (major < mTouchMinMajor) major = mTouchMinMajor;
                total += major;

                if (Float.isNaN(mTouchUpper) || major > mTouchUpper) {
                    mTouchUpper = major;
                }
                if (Float.isNaN(mTouchLower) || major < mTouchLower) {
                    mTouchLower = major;
                }

                if (hasLastAccepted) {
                    final int directionSig = (int) Math.signum(major - mTouchHistoryLastAccepted);
                    if (directionSig != mTouchHistoryDirection ||
                            (directionSig == 0 && mTouchHistoryDirection == 0)) {
                        mTouchHistoryDirection = directionSig;
                        final long time = h < historySize ? ev.getHistoricalEventTime(h)
                                : ev.getEventTime();
                        mTouchHistoryLastAcceptedTime = time;
                        accept = false;
                    }
                }
            }
            sampleCount += pointerSampleCount;
        }

        final float avg = total / sampleCount;

        if (accept) {
            float newAccepted = (mTouchUpper + mTouchLower + avg) / 3;
            mTouchUpper = (mTouchUpper + newAccepted) / 2;
            mTouchLower = (mTouchLower + newAccepted) / 2;
            mTouchHistoryLastAccepted = newAccepted;
            mTouchHistoryDirection = 0;
            mTouchHistoryLastAcceptedTime = ev.getEventTime();
        }
    }

    /**
     * Clear all touch history tracking. Useful in ACTION_CANCEL or ACTION_UP.
     * @see #addTouchHistory(MotionEvent)
     */
    private void clearTouchHistory() {
        mTouchUpper = Float.NaN;
        mTouchLower = Float.NaN;
        mTouchHistoryLastAccepted = Float.NaN;
        mTouchHistoryDirection = 0;
        mTouchHistoryLastAcceptedTime = 0;
    }

    /**
     * Accepts MotionEvents and dispatches events to a {@link OnRotateGestureListener}
     * when appropriate.
     *
     * <p>Applications should pass a complete and consistent event stream to this method.
     * A complete and consistent event stream involves all MotionEvents from the initial
     * ACTION_DOWN to the final ACTION_UP or ACTION_CANCEL.</p>
     *
     * @param event The event to process
     * @return true if the event was processed and the detector wants to receive the
     *         rest of the MotionEvents in this event stream.
     */
    public boolean onTouchEvent(MotionEvent event) {
        if (mInputEventConsistencyVerifier != null) {
            mInputEventConsistencyVerifier.onTouchEvent(event, 0);
        }

        final int action = event.getActionMasked();

        final boolean streamComplete = action == MotionEvent.ACTION_UP ||
                action == MotionEvent.ACTION_CANCEL;
        if (action == MotionEvent.ACTION_DOWN || streamComplete) {
            // Reset any rotate in progress with the listener.
            // If it's an ACTION_DOWN we're beginning a new event stream.
            // This means the app probably didn't give us all the events. Shame on it.
            if (mInProgress) {
                mListener.onRotateEnd(this);
                mInProgress = false;
                mInitialSpan = 0;
            }

            if (streamComplete) {
                clearTouchHistory();
                return true;
            }
        }

        final boolean configChanged = action == MotionEvent.ACTION_DOWN ||
                action == MotionEvent.ACTION_POINTER_UP ||
                action == MotionEvent.ACTION_POINTER_DOWN;
        final boolean pointerUp = action == MotionEvent.ACTION_POINTER_UP;
        final int skipIndex = pointerUp ? event.getActionIndex() : -1;

        // Determine focal point
        float sumX = 0, sumY = 0;
        final int count = event.getPointerCount();
        for (int i = 0; i < count; i++) {
            if (skipIndex == i) continue;
            sumX += event.getX(i);
            sumY += event.getY(i);
        }
        final int div = pointerUp ? count - 1 : count;
        final float focusX = sumX / div;
        final float focusY = sumY / div;


        addTouchHistory(event);

        // Determine average deviation from focal point
        float devSumX = 0, devSumY = 0;
        for (int i = 0; i < count; i++) {
            if (skipIndex == i) continue;

            // Convert the resulting diameter into a radius.
            final float touchSize = mTouchHistoryLastAccepted / 2;
            devSumX += Math.abs(event.getX(i) - focusX) + touchSize;
            devSumY += Math.abs(event.getY(i) - focusY) + touchSize;
        }
        final float devX = devSumX / div;
        final float devY = devSumY / div;

        // Span is the average distance between touch points through the focal point;
        // i.e. the diameter of the circle with a radius of the average deviation from
        // the focal point.
        final float spanX = devX * 2;
        final float spanY = devY * 2;
        final float span = FloatMath.sqrt(spanX * spanX + spanY * spanY);

        // Dispatch begin/end events as needed.
        // If the configuration changes, notify the app to reset its current state by beginning
        // a fresh rotate event stream.
        final boolean wasInProgress = mInProgress;
        mFocusX = focusX;
        mFocusY = focusY;
        if (mInProgress && (span < mMinSpan || configChanged)) {
            mListener.onRotateEnd(this);
            mInProgress = false;
            mInitialSpan = span;
        }
        if (configChanged) {
            mPrevSpanX = mCurrSpanX = spanX;
            mPrevSpanY = mCurrSpanY = spanY;
            mInitialSpan = mPrevSpan = mCurrSpan = span;
        }
        if (!mInProgress && span >= mMinSpan &&
                (wasInProgress || Math.abs(span - mInitialSpan) > mSpanSlop)) {
            mPrevSpanX = mCurrSpanX = spanX;
            mPrevSpanY = mCurrSpanY = spanY;
            mPrevSpan = mCurrSpan = span;
            mInProgress = mListener.onRotateBegin(this);
        }

        // Handle motion; focal point and span/rotate factor are changing.
        if (action == MotionEvent.ACTION_MOVE) {
            mCurrSpanX = spanX;
            mCurrSpanY = spanY;
            mCurrSpan = span;

            boolean updatePrev = true;
            if (mInProgress) {
                updatePrev = mListener.onRotate(this);
            }

            if (updatePrev) {
                mPrevSpanX = mCurrSpanX;
                mPrevSpanY = mCurrSpanY;
                mPrevSpan = mCurrSpan;
            }
        }

        return true;
    }

    /**
     * Returns {@code true} if a rotate gesture is in progress.
     */
    public boolean isInProgress() {
        return mInProgress;
    }

    /**
     * Get the X coordinate of the current gesture's focal point.
     * If a gesture is in progress, the focal point is between
     * each of the pointers forming the gesture.
     *
     * If {@link #isInProgress()} would return false, the result of this
     * function is undefined.
     *
     * @return X coordinate of the focal point in pixels.
     */
    public float getFocusX() {
        return mFocusX;
    }

    /**
     * Get the Y coordinate of the current gesture's focal point.
     * If a gesture is in progress, the focal point is between
     * each of the pointers forming the gesture.
     *
     * If {@link #isInProgress()} would return false, the result of this
     * function is undefined.
     *
     * @return Y coordinate of the focal point in pixels.
     */
    public float getFocusY() {
        return mFocusY;
    }

    /**
     * Return the average distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Distance between pointers in pixels.
     */
    public float getCurrentSpan() {
        return mCurrSpan;
    }

    /**
     * Return the average X distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Distance between pointers in pixels.
     */
    public float getCurrentSpanX() {
        return mCurrSpanX;
    }

    /**
     * Return the average Y distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Distance between pointers in pixels.
     */
    public float getCurrentSpanY() {
        return mCurrSpanY;
    }

    /**
     * Return the previous average distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Previous distance between pointers in pixels.
     */
    public float getPreviousSpan() {
        return mPrevSpan;
    }

    /**
     * Return the previous average X distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Previous distance between pointers in pixels.
     */
    public float getPreviousSpanX() {
        return mPrevSpanX;
    }

    /**
     * Return the previous average Y distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Previous distance between pointers in pixels.
     */
    public float getPreviousSpanY() {
        return mPrevSpanY;
    }

    /**
     * Return the rotate factor from the previous rotate event to the current
     * event. This value is defined as
     * ({@link #getCurrentSpan()} / {@link #getPreviousSpan()}).
     *
     * @return The current rotate factor.
     */
    public float getRotateFactor() {
        return mPrevSpan > 0 ? mCurrSpan / mPrevSpan : 1;
    }

    /**
     * Return the time difference in milliseconds between the previous
     * accepted rotate event and the current rotate event.
     *
     * @return Time difference since the last rotate event in milliseconds.
     */
    public long getTimeDelta() {
        return mCurrTime - mPrevTime;
    }

    /**
     * Return the event time of the current event being processed.
     *
     * @return Current event time in milliseconds.
     */
    public long getEventTime() {
        return mCurrTime;
    }
}
