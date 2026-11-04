package com.hypr.hyprwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class QuickActionsWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)

            fun makePending(actionUri: String, requestCode: Int): PendingIntent {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(actionUri)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                return PendingIntent.getActivity(
                    context, requestCode, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            views.setOnClickPendingIntent(R.id.widget_btn_income, makePending("hyprwise:///money/add?type=income", 201))
            views.setOnClickPendingIntent(R.id.widget_btn_expense, makePending("hyprwise:///money/add?type=expense", 202))
            views.setOnClickPendingIntent(R.id.widget_btn_lend, makePending("hyprwise:///debts/add?type=lent", 203))
            views.setOnClickPendingIntent(R.id.widget_btn_borrow, makePending("hyprwise:///debts/add?type=borrowed", 204))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
