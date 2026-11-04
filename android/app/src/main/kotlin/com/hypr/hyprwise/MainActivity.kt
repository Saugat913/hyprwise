package com.hypr.hyprwise

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val WIDGET_CHANNEL = "com.hypr.hyprwise/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgets") {
                updateAllAppWidgets()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun updateAllAppWidgets() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

            // Shift Widget
            val shiftComponent = ComponentName(applicationContext, ShiftWidgetProvider::class.java)
            val shiftIds = appWidgetManager.getAppWidgetIds(shiftComponent)
            if (shiftIds != null && shiftIds.isNotEmpty()) {
                val intent = Intent(applicationContext, ShiftWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, shiftIds)
                }
                applicationContext.sendBroadcast(intent)
            }

            // Quick Actions Widget
            val actionsComponent = ComponentName(applicationContext, QuickActionsWidgetProvider::class.java)
            val actionIds = appWidgetManager.getAppWidgetIds(actionsComponent)
            if (actionIds != null && actionIds.isNotEmpty()) {
                val intent = Intent(applicationContext, QuickActionsWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, actionIds)
                }
                applicationContext.sendBroadcast(intent)
            }

            // HyprAI Widget
            val aiComponent = ComponentName(applicationContext, HyprAiWidgetProvider::class.java)
            val aiIds = appWidgetManager.getAppWidgetIds(aiComponent)
            if (aiIds != null && aiIds.isNotEmpty()) {
                val intent = Intent(applicationContext, HyprAiWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, aiIds)
                }
                applicationContext.sendBroadcast(intent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
