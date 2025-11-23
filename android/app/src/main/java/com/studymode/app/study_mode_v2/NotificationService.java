package com.studymode.app.study_mode_v2;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public class NotificationService extends Service {
    private static final String TAG = "StudyModeNotificationService";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Notification Service created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Notification Service started");
        return START_STICKY; // Restart service if killed
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null; // We don't provide binding
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "Notification Service destroyed");
    }
}