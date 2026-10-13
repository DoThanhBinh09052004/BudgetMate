package com.budgetmate.bugdetmate;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.provider.Settings;
import androidx.annotation.NonNull;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.budgetmate.bugdetmate/notification_service";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "checkNotificationPermission":
                            result.success(isNotificationServiceEnabled());
                            break;

                        case "requestNotificationPermission":
                            openNotificationListenerSettings();
                            result.success(true);
                            break;

                        case "rebindService":
                            rebindNotificationService();
                            result.success(true);
                            break;

                        case "updateWhitelist":
                            List<String> packages = call.argument("packages");
                            if (packages != null) {
                                SharedPreferences prefs = getSharedPreferences(
                                        BudgetMateNotificationService.PREFS_NAME,
                                        Context.MODE_PRIVATE
                                );
                                Set<String> packageSet = new HashSet<>(packages);
                                prefs.edit()
                                        .putStringSet(BudgetMateNotificationService.KEY_WHITELIST, packageSet)
                                        .apply();
                                result.success(true);
                            } else {
                                result.error("INVALID_ARGUMENT", "Package list is null", null);
                            }
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    private boolean isNotificationServiceEnabled() {
        ComponentName cn = new ComponentName(this, BudgetMateNotificationService.class);
        String flat = Settings.Secure.getString(getContentResolver(), "enabled_notification_listeners");
        return flat != null && flat.contains(cn.flattenToString());
    }

    private void openNotificationListenerSettings() {
        try {
            Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
            startActivity(intent);
        } catch (Exception e) {
            Intent intent = new Intent(Settings.ACTION_SETTINGS);
            startActivity(intent);
        }
    }

    /**
     * Tự động rebind service cho Xiaomi/MIUI khi hệ thống âm thầm kill listener.
     */
    private void rebindNotificationService() {
        try {
            PackageManager pm = getPackageManager();
            ComponentName componentName = new ComponentName(this, BudgetMateNotificationService.class);
            pm.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
            );
            pm.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
            );
        } catch (Exception ignored) {
        }
    }
}
