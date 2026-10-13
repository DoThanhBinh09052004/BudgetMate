package com.budgetmate.bugdetmate;

import android.app.Notification;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

import java.io.File;
import java.util.Collections;
import java.util.Set;

/**
 * Pure Java NotificationListenerService with dynamic package whitelist and
 * raw buffer pattern. Writes directly to SQLite to guarantee zero data loss
 * even if the Flutter engine is detached or sleeping.
 */
public class BudgetMateNotificationService extends NotificationListenerService {

    private static final String TAG = "BudgetMateNotifService";
    public static final String PREFS_NAME = "BudgetMatePrefs";
    public static final String KEY_WHITELIST = "whitelist_packages";
    private static final String DB_NAME = "budgetmate.db";

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        Log.i(TAG, "BudgetMateNotificationService connected successfully.");
    }

    @Override
    public void onListenerDisconnected() {
        super.onListenerDisconnected();
        Log.w(TAG, "BudgetMateNotificationService disconnected.");
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        if (sbn == null) return;

        String packageName = sbn.getPackageName();
        if (packageName == null) return;

        // Dynamic Whitelist check from SharedPreferences
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        Set<String> whitelist = prefs.getStringSet(KEY_WHITELIST, Collections.emptySet());

        if (whitelist == null || !whitelist.contains(packageName)) {
            // Not a monitored financial app
            return;
        }

        Notification notification = sbn.getNotification();
        if (notification == null) return;

        Bundle extras = notification.extras;
        String title = "";
        String text = "";

        if (extras != null) {
            CharSequence titleCs = extras.getCharSequence(Notification.EXTRA_TITLE);
            if (titleCs != null) {
                title = titleCs.toString();
            }

            CharSequence bigTextCs = extras.getCharSequence(Notification.EXTRA_BIG_TEXT);
            if (bigTextCs != null) {
                text = bigTextCs.toString();
            } else {
                CharSequence textCs = extras.getCharSequence(Notification.EXTRA_TEXT);
                if (textCs != null) {
                    text = textCs.toString();
                }
            }
        }

        String sbnKey = sbn.getKey();
        long postTimeSeconds = sbn.getPostTime() / 1000L;

        saveToRawBuffer(packageName, sbnKey, postTimeSeconds, title, text);
    }

    private void saveToRawBuffer(String packageName, String sbnKey, long postTime, String title, String text) {
        SQLiteDatabase db = null;
        try {
            File dbFile = getDatabasePath(DB_NAME);
            if (!dbFile.getParentFile().exists()) {
                dbFile.getParentFile().mkdirs();
            }

            db = SQLiteDatabase.openOrCreateDatabase(dbFile, null);

            // Ensure raw_notifications table exists
            db.execSQL("CREATE TABLE IF NOT EXISTS raw_notifications (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "package_name TEXT NOT NULL, " +
                    "sbn_key TEXT UNIQUE NOT NULL, " +
                    "post_time INTEGER NOT NULL, " +
                    "title TEXT, " +
                    "text TEXT, " +
                    "is_processed INTEGER DEFAULT 0);");

            ContentValues values = new ContentValues();
            values.put("package_name", packageName);
            values.put("sbn_key", sbnKey);
            values.put("post_time", postTime);
            values.put("title", title);
            values.put("text", text);
            values.put("is_processed", 0);

            // Layer 1 Deduplication: CONFLICT_IGNORE on unique sbn_key
            long id = db.insertWithOnConflict("raw_notifications", null, values, SQLiteDatabase.CONFLICT_IGNORE);
            if (id != -1) {
                Log.d(TAG, "Saved raw notification to buffer, id: " + id + " from " + packageName);
            } else {
                Log.d(TAG, "Duplicate raw notification ignored for key: " + sbnKey);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to save raw notification to buffer: " + e.getMessage(), e);
        } finally {
            if (db != null && db.isOpen()) {
                db.close();
            }
        }
    }
}
