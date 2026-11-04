package com.hypr.hyprwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class ShiftWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jobName = prefs.getString("flutter.widget_shift_job", "CAFE") ?: "CAFE"
            val subtitle = prefs.getString("flutter.widget_shift_subtitle", "time and pay rates") ?: "time and pay rates"

            val views = RemoteViews(context.packageName, R.layout.widget_shift)
            views.setTextViewText(R.id.widget_shift_job, jobName.uppercase())
            views.setTextViewText(R.id.widget_shift_subtitle, subtitle)

            // Deep link for breaking/resuming shift
            val breakIntent = Intent(Intent.ACTION_VIEW, Uri.parse("hyprwise:///work/shift/live?action=break")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val breakPending = PendingIntent.getActivity(
                context, 101, breakIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_shift_btn_break, breakPending)

            // Deep link for ending shift
            val endIntent = Intent(Intent.ACTION_VIEW, Uri.parse("hyprwise:///work/shift/live?action=end")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val endPending = PendingIntent.getActivity(
                context, 102, endIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_shift_btn_end, endPending)

            // Deep link on whole container
            val containerIntent = Intent(Intent.ACTION_VIEW, Uri.parse("hyprwise:///work/shift/live")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val containerPending = PendingIntent.getActivity(
                context, 100, containerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_shift_container, containerPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
