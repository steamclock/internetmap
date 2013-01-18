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
import android.view.MotionEvent;


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

    private float mCurrSlope;
    private float mPrevSlope;
    private float mInitialSlope;
    private long mCurrTime;
    private long mPrevTime;
    private boolean mInProgress;

    // Bounds for recently seen values
    private float mTouchUpper;
    private float mTouchLower;
    private float mTouchHistoryLastAccepted;
    private int mTouchHistoryDirection;
    private long mTouchHistoryLastAcceptedTime;
    private int mTouchMinMajor;

    private static final long TOUCH_STABILIZE_TIME = 128; // ms
    private static final int TOUCH_MIN_MAJOR = 48; // dp
    //android has no rotate slop, so we make our own. hopefully it's ok.
    private static final float mSlopeSlop = 0.087f; //about 5 degrees (I just picked something small at random)

    public RotateGestureDetector(Context context, OnRotateGestureListener listener) {
        mContext = context;
        mListener = listener;

        final Resources res = context.getResources();
        mTouchMinMajor = res.getDimensionPixelSize(TOUCH_MIN_MAJOR);
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
                mInitialSlope = 0;
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

        addTouchHistory(event);

        // Determine slope (in radians) between first two pointers.
        //FIXME how will this behave with >2 fingers?
        final int count = event.getPointerCount();
        //we need at least two points to calculate a slope
        final int needed = pointerUp ? 3 : 2;

        final boolean haveSlope = (count >= needed);
        float slope = 0;
        if (haveSlope) {
            float x1 = 0, y1 = 0, x2 = 0, y2 = 0;
            boolean gotFirst = false;
            for (int i = 0; i < count; i++) {
                if (skipIndex == i) continue;
                if (!gotFirst) {
                    x1 = event.getX(i);
                    y1 = event.getY(i);
                    gotFirst = true;
                } else {
                    x2 = event.getX(i);
                    y2 = event.getY(i);
                    break;
                }
            }
            final float dX = x1 - x2;
            final float dY = y1 - y2;
            slope = (float) Math.atan2(dY, dX);
        }

        // Dispatch begin/end events as needed.
        // If the configuration changes, notify the app to reset its current state by beginning
        // a fresh rotate event stream.
        final boolean wasInProgress = mInProgress;
        //mFocusX = focusX;
        //mFocusY = focusY;
        if (mInProgress && (!haveSlope || configChanged)) {
            mListener.onRotateEnd(this);
            mInProgress = false;
            mInitialSlope = slope;
        }
        if (configChanged) {
            mInitialSlope = mPrevSlope = mCurrSlope = slope;
        }
        if (!mInProgress && haveSlope &&
                (wasInProgress || Math.abs(slope - mInitialSlope) > mSlopeSlop)) {
            mPrevSlope = mCurrSlope = slope;
            mInProgress = mListener.onRotateBegin(this);
        }

        // Handle motion; focal point and span/rotate factor are changing.
        if (action == MotionEvent.ACTION_MOVE) {
            mCurrSlope = slope;

            boolean updatePrev = true;
            if (mInProgress) {
                updatePrev = mListener.onRotate(this);
            }

            if (updatePrev) {
                mPrevSlope = mCurrSlope;
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
    public float getCurrentSlope() {
        return mCurrSlope;
    }

    /**
     * Return the previous average distance between each of the pointers forming the
     * gesture in progress through the focal point.
     *
     * @return Previous distance between pointers in pixels.
     */
    public float getPreviousSlope() {
        return mPrevSlope;
    }

    /**
     * Return the rotate factor from the previous rotate event to the current
     * event. This value is defined as
     * ({@link #getCurrentSlope()} - {@link #getPreviousSlope()}).
     *
     * @return The current rotate factor.
     */
    public float getRotateFactor() {
        return mCurrSlope - mPrevSlope; //FIXME what if there is no prev?
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
