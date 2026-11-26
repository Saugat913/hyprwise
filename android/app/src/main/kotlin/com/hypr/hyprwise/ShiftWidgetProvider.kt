package com.hypr.hyprwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToLong

class ShiftWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            } catch (_: Throwable) {
                // Fallback minimal safe view so launcher never shows "Couldn't add widget"
                try {
                    val fallback = RemoteViews(context.packageName, R.layout.widget_shift)
                    appWidgetManager.updateAppWidget(appWidgetId, fallback)
                } catch (_: Throwable) {}
            }
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun SharedPreferences.readLong(key: String, defaultValue: Long = 0L): Long {
            val raw = all[key] ?: return defaultValue
            return when (raw) {
                is Long -> raw
                is Int -> raw.toLong()
                is Number -> raw.toLong()
                is String -> raw.toLongOrNull() ?: defaultValue
                else -> defaultValue
            }
        }

        private fun SharedPreferences.readBool(key: String, defaultValue: Boolean = false): Boolean {
            val raw = all[key] ?: return defaultValue
            return when (raw) {
                is Boolean -> raw
                is String -> raw.equals("true", ignoreCase = true)
                is Number -> raw.toInt() != 0
                else -> defaultValue
            }
        }

        private fun formatDuration(totalSeconds: Long): String {
            val clamped = max(0L, totalSeconds)
            val h = clamped / 3600
            val m = (clamped % 3600) / 60
            val s = clamped % 60
            return String.format(Locale.US, "%02d:%02d:%02d", h, m, s)
        }

        private fun computeLiveEarningsMinor(
            workedSeconds: Long,
            rateMinor: Long,
            otThresholdMin: Long,
            otRateMinor: Long
        ): Long {
            if (workedSeconds <= 0L || rateMinor <= 0L) return 0L
            val thresholdSec = otThresholdMin * 60L
            return if (otThresholdMin > 0L && otRateMinor > 0L && workedSeconds > thresholdSec) {
                val regSec = thresholdSec
                val otSec = workedSeconds - thresholdSec
                val regPay = (regSec.toDouble() * rateMinor.toDouble()) / 3600.0
                val otPay = (otSec.toDouble() * otRateMinor.toDouble()) / 3600.0
                (regPay + otPay).roundToLong()
            } else {
                ((workedSeconds.toDouble() * rateMinor.toDouble()) / 3600.0).roundToLong()
            }
        }

        private fun formatMoney(minorUnits: Long, symbol: String, currencyCode: String): String {
            val major = minorUnits / 100.0
            val nf = NumberFormat.getNumberInstance(Locale.US).apply {
                val isJpy = currencyCode.equals("JPY", ignoreCase = true)
                minimumFractionDigits = if (isJpy && minorUnits % 100L == 0L) 0 else 2
                maximumFractionDigits = if (isJpy && minorUnits % 100L == 0L) 0 else 2
            }
            return "$symbol${nf.format(major)}"
        }

        private fun makeDeepLinkPendingIntent(
            context: Context,
            uriString: String,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse(uriString)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val jobName = prefs.getString("widget_shift_job", null)?.trim().orEmpty()
            val isActive = prefs.readBool("widget_shift_active", false) &&
                    jobName.isNotEmpty() &&
                    jobName != "NO ACTIVE SHIFT"
            val isOnBreak = prefs.readBool("widget_shift_is_on_break", false)
            val effectiveStartMs = prefs.readLong("widget_shift_effective_start_ms", 0L)
            val storedWorkedSec = prefs.readLong("widget_shift_worked_seconds", 0L)
            val breakMinutes = prefs.readLong("widget_shift_break_minutes", 0L)
            val rateMinor = prefs.readLong("widget_shift_rate_minor", 0L)
            val otThresholdMin = prefs.readLong("widget_shift_ot_threshold_min", 0L)
            val otRateMinor = prefs.readLong("widget_shift_ot_rate_minor", 0L)
            val currencyCode = prefs.getString("widget_shift_currency_code", "USD") ?: "USD"
            val currencySymbol = prefs.getString("widget_shift_currency_symbol", "$") ?: "$"
            val rateLabel = prefs.getString("widget_shift_rate_label", null)?.trim().orEmpty()
            val storedEarningsLabel = prefs.getString("widget_shift_earnings_label", null)?.trim().orEmpty()
            val defaultJob = prefs.getString("widget_default_job", null)?.trim().orEmpty()
            val defaultRateLabel = prefs.getString("widget_default_rate_label", null)?.trim().orEmpty()
            val storedSubtitle = prefs.getString("widget_shift_subtitle", null)?.trim().orEmpty()

            val views = RemoteViews(context.packageName, R.layout.widget_shift)

            if (isActive) {
                views.setTextViewText(R.id.widget_shift_job, jobName)
                views.setViewVisibility(R.id.widget_shift_live_row, View.VISIBLE)
                views.setViewVisibility(R.id.widget_shift_active_actions, View.VISIBLE)
                views.setViewVisibility(R.id.widget_shift_btn_start, View.GONE)

                val nowMs = System.currentTimeMillis()
                val liveWorkedSec = if (!isOnBreak && effectiveStartMs > 0L) {
                    max(0L, (nowMs - effectiveStartMs) / 1000L)
                } else {
                    max(0L, storedWorkedSec)
                }

                // Live earnings computation natively in Kotlin (falls back to stored label if rate is 0)
                val earningsText = if (rateMinor > 0L) {
                    val minor = computeLiveEarningsMinor(liveWorkedSec, rateMinor, otThresholdMin, otRateMinor)
                    formatMoney(minor, currencySymbol, currencyCode)
                } else if (storedEarningsLabel.isNotEmpty()) {
                    storedEarningsLabel
                } else {
                    formatMoney(0L, currencySymbol, currencyCode)
                }
                views.setTextViewText(R.id.widget_shift_earnings, earningsText)

                if (isOnBreak) {
                    // Status chip: Amber "On Break"
                    views.setInt(R.id.widget_shift_status_chip, "setBackgroundResource", R.drawable.widget_chip_break_bg)
                    views.setImageViewResource(R.id.widget_shift_status_dot, R.drawable.ic_widget_dot_break)
                    views.setTextViewText(R.id.widget_shift_status_label, "On Break")
                    views.setTextColor(R.id.widget_shift_status_label, context.getColor(R.color.widget_amber))

                    // Frozen monospace readout instead of ticking chronometer
                    views.setChronometer(R.id.widget_shift_chronometer, SystemClock.elapsedRealtime(), "%s", false)
                    views.setViewVisibility(R.id.widget_shift_chronometer, View.GONE)
                    views.setViewVisibility(R.id.widget_shift_timer_paused, View.VISIBLE)
                    views.setTextViewText(R.id.widget_shift_timer_paused, formatDuration(liveWorkedSec))

                    // Action button: Resume
                    views.setImageViewResource(R.id.widget_shift_btn_break_icon, R.drawable.ic_widget_resume)
                    views.setTextViewText(R.id.widget_shift_btn_break_label, "Resume")
                } else {
                    // Status chip: Green "Live"
                    views.setInt(R.id.widget_shift_status_chip, "setBackgroundResource", R.drawable.widget_chip_live_bg)
                    views.setImageViewResource(R.id.widget_shift_status_dot, R.drawable.ic_widget_dot_active)
                    views.setTextViewText(R.id.widget_shift_status_label, "Live")
                    views.setTextColor(R.id.widget_shift_status_label, context.getColor(R.color.widget_green))

                    // Native zero-battery ticking Chronometer!
                    val elapsedMs = max(0L, liveWorkedSec * 1000L)
                    val base = SystemClock.elapsedRealtime() - elapsedMs
                    views.setViewVisibility(R.id.widget_shift_timer_paused, View.GONE)
                    views.setViewVisibility(R.id.widget_shift_chronometer, View.VISIBLE)
                    views.setChronometer(R.id.widget_shift_chronometer, base, "%s", true)

                    // Action button: Break
                    views.setImageViewResource(R.id.widget_shift_btn_break_icon, R.drawable.ic_widget_coffee)
                    views.setTextViewText(R.id.widget_shift_btn_break_label, "Break")
                }

                // Subtitle: Rate + break summary
                val subtitleParts = mutableListOf<String>()
                if (rateLabel.isNotEmpty()) subtitleParts.add(rateLabel)
                if (breakMinutes > 0L) subtitleParts.add("${breakMinutes}m break")
                val metaSubtitle = if (subtitleParts.isNotEmpty()) {
                    subtitleParts.joinToString(" · ")
                } else {
                    if (isOnBreak) "Timer paused" else "Shift in progress"
                }
                views.setTextViewText(R.id.widget_shift_subtitle, metaSubtitle)

                // Deep links targeting MainActivity explicitly
                views.setOnClickPendingIntent(
                    R.id.widget_shift_btn_break,
                    makeDeepLinkPendingIntent(context, "hyprwise:///work/shift/live?action=break", 101)
                )
                views.setOnClickPendingIntent(
                    R.id.widget_shift_btn_end,
                    makeDeepLinkPendingIntent(context, "hyprwise:///work/shift/live?action=end", 102)
                )
                views.setOnClickPendingIntent(
                    R.id.widget_shift_container,
                    makeDeepLinkPendingIntent(context, "hyprwise:///work/shift/live", 100)
                )
            } else {
                // Idle state: show ready job & rate in clean Hyprwise card style
                val idleTitle = if (defaultJob.isNotEmpty()) defaultJob else "Shift Tracker"
                val idleSubtitle = when {
                    defaultJob.isNotEmpty() && defaultRateLabel.isNotEmpty() -> "Ready to clock in · $defaultRateLabel"
                    storedSubtitle.isNotEmpty() -> storedSubtitle
                    else -> "Tap to start tracking"
                }

                views.setTextViewText(R.id.widget_shift_job, idleTitle)
                views.setTextViewText(R.id.widget_shift_subtitle, idleSubtitle)

                views.setInt(R.id.widget_shift_status_chip, "setBackgroundResource", R.drawable.widget_chip_idle_bg)
                views.setImageViewResource(R.id.widget_shift_status_dot, R.drawable.ic_widget_dot_inactive)
                views.setTextViewText(R.id.widget_shift_status_label, "Ready")
                views.setTextColor(R.id.widget_shift_status_label, context.getColor(R.color.widget_muted))

                views.setChronometer(R.id.widget_shift_chronometer, SystemClock.elapsedRealtime(), "%s", false)
                views.setViewVisibility(R.id.widget_shift_live_row, View.GONE)
                views.setViewVisibility(R.id.widget_shift_active_actions, View.GONE)
                views.setViewVisibility(R.id.widget_shift_btn_start, View.VISIBLE)

                val startPending = makeDeepLinkPendingIntent(context, "hyprwise:///work/shift/start", 103)
                views.setOnClickPendingIntent(R.id.widget_shift_btn_start, startPending)
                views.setOnClickPendingIntent(R.id.widget_shift_container, startPending)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
