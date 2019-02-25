package com.peer1.internetmap.utils;

import timber.log.Timber;

/**
 * Original implementation included usage of Junit's Assert class in the app modules' files.
 * Once updated to use build tools v28, this class appears to no longer be available in the app module.
 * As an intermediate work around, I created an implementation of those functions that spit out
 * logs if the assertions fail.
 */
public class Assert {

    public static void assertNotNull(Object object) {
        if (object == null) {
            Timber.e(new Throwable("Assert.notNull, object is null"));
        }
    }

    public static void assertNull(Object object) {
        if (object != null) {
            Timber.e(new Throwable("Assert.assertNull, object is not null"));
        }
    }

    public static void assertTrue(Boolean isTrue) {
        if (!isTrue) {
            Timber.e(new Throwable("Assert.assertTrue, statement is false"));
        }
    }

    public static void assertTrue(String message, Boolean isTrue) {
        if (!isTrue) {
            Timber.e(new Throwable("Assert.assertTrue, " + message));
        }
    }
}
