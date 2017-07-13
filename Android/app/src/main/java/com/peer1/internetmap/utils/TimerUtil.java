package com.peer1.internetmap.utils;

import android.util.Log;

import java.util.HashMap;

/**
 * Testing utility
 * Track multiple simple timers based on a string ID.
 * <p>
 * Note, Timers do not persist through app tear down.
 */
public class TimerUtil {

    /**
     * Singleton instance
     */
    private static TimerUtil instance;
    public static TimerUtil getInstance() {
        if (instance == null) {
            instance = new TimerUtil();
        }

        return instance;
    }

    /**
     * Timer
     */
    public static class Timer {
        public String id;
        public Long start;
        public Long stop;

        public Timer(String id) {
            this.id = id;
        }

        public Timer(String id, Long start) {
            this.id = id;
            this.start = start;
        }

        public String getElapsedDescription() {
            if (start == null) {
                return String.format("%s has not started", id);
            } else if (stop == null) {
                Long now = System.currentTimeMillis();
                return String.format("%s @ %d ms", id, now - start);
            }

            return String.format("%s took %d ms", id, stop - start);
        }
    }

    private HashMap<String, Timer> timers = new HashMap<>();


    //=====================================================================
    // Public methods
    //=====================================================================

    /**
     * Starts a timer, hashed on the given ID. If the ID already exists, nothing happens. If yo uneed to
     * reset a timer, call stop first.
     * @param id Lookup ID for the Timer.
     */
    public void start(String id) {
        if (timers.containsKey(id)) {
            return;
        }

        Timer newTimer = new Timer(id, System.currentTimeMillis());
        timers.put(id, newTimer);
    }

    /**
     * Stops a timer, hashed on the given ID.
     * @param id Lookup ID for the Timer.
     */
    public String stop(String id) {
        if (!timers.containsKey(id)) {
            return String.format("%s does not exist", id);
        }

        Timer timer = timers.get(id);
        timer.stop = System.currentTimeMillis();
        return timer.getElapsedDescription();
    }

    /**
     * Stops a timer, logs the elapased time to the console, and removes the Timer from cache.
     * @param id Lookup ID for the Timer.
     */
    public void stopLogRemove(String id) {
        Log.v("Timers", stop(id));
        remove(id);
    }

    /**
     * Removes a Timer from cache
     * @param id Lookup ID for the Timer.
     */
    public void remove(String id) {
        if (timers.containsKey(id)) {
            timers.remove(id);
        }
    }
}