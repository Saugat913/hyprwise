package com.hypr.hyprwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
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
            val jobName = prefs.getString("flutter.widget_shift_job", null)
            val subtitle = prefs.getString("flutter.widget_shift_subtitle", null)
            val isOnBreak = prefs.getBoolean("flutter.widget_shift_is_on_break", false)
            val hasActiveShift = prefs.getBoolean("flutter.widget_shift_active", false) &&
                    !jobName.isNullOrEmpty() &&
                    jobName != "NO ACTIVE SHIFT"

            val views = RemoteViews(context.packageName, R.layout.widget_shift)

            if (hasActiveShift) {
                views.setTextViewText(R.id.widget_shift_job, jobName.uppercase())
                views.setTextViewText(R.id.widget_shift_subtitle, subtitle ?: "Active Shift")
                views.setImageViewResource(
                    R.id.widget_shift_status_icon,
                    if (isOnBreak) R.drawable.ic_widget_dot_break else R.drawable.ic_widget_dot_active
                )
                views.setTextViewText(R.id.widget_shift_btn_break, if (isOnBreak) "resume" else "break")

                views.setViewVisibility(R.id.widget_shift_active_actions, View.VISIBLE)
                views.setViewVisibility(R.id.widget_shift_btn_start, View.GONE)

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
            } else {
                views.setTextViewText(R.id.widget_shift_job, "NO ACTIVE SHIFT")
                views.setTextViewText(R.id.widget_shift_subtitle, subtitle ?: "Tap to start a shift")
                views.setImageViewResource(R.id.widget_shift_status_icon, R.drawable.ic_widget_dot_inactive)

                views.setViewVisibility(R.id.widget_shift_active_actions, View.GONE)
                views.setViewVisibility(R.id.widget_shift_btn_start, View.VISIBLE)

                // Deep link for starting shift
                val startIntent = Intent(Intent.ACTION_VIEW, Uri.parse("hyprwise:///work/shift/start")).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val startPending = PendingIntent.getActivity(
                    context, 103, startIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_shift_btn_start, startPending)
                views.setOnClickPendingIntent(R.id.widget_shift_container, startPending)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
