package com.hypr.hyprwise

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val widgetChannel = "com.hypr.hyprwise/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgets") {
                val target = call.argument<String>("target") ?: "all"
                updateAppWidgets(target)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun updateAppWidgets(target: String) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

            fun refreshProvider(providerClass: Class<*>) {
                val component = ComponentName(applicationContext, providerClass)
                val ids = appWidgetManager.getAppWidgetIds(component)
                if (ids != null && ids.isNotEmpty()) {
                    val intent = Intent(applicationContext, providerClass).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    }
                    applicationContext.sendBroadcast(intent)
                }
            }

            if (target == "shift" || target == "all") {
                refreshProvider(ShiftWidgetProvider::class.java)
            }
            if (target == "all") {
                refreshProvider(QuickActionsWidgetProvider::class.java)
                refreshProvider(HyprAiWidgetProvider::class.java)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
