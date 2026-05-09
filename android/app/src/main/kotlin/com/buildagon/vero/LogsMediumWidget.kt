package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews

class LogsMediumWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val pending = goAsync()
        Thread {
            try {
                for (id in appWidgetIds) {
                    updateWidget(context, appWidgetManager, id)
                }
            } finally {
                pending.finish()
            }
        }.start()
    }

    companion object {
        private val LOG_IDS = listOf(
            Triple(R.id.log_row_1, R.id.log_msg_1, R.id.log_time_1),
            Triple(R.id.log_row_2, R.id.log_msg_2, R.id.log_time_2),
            Triple(R.id.log_row_3, R.id.log_msg_3, R.id.log_time_3),
            Triple(R.id.log_row_4, R.id.log_msg_4, R.id.log_time_4),
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_logs_medium)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)

            val projectName = VeroWidgetUtils.getProjectName(
                context, "vero_logs_project_name", "Select Project"
            )
            val deployStatus = VeroWidgetUtils.getString(context, "vero_logs_deployment_status", "—")
            val lastUpdated = VeroWidgetUtils.getString(context, "vero_last_updated")
            val logsJson = VeroWidgetUtils.getString(context, "vero_logs_data")
            val logs = if (logsJson.isNotEmpty()) VeroWidgetUtils.parseJsonArray(logsJson) else emptyList()

            views.setTextViewText(R.id.widget_project_name, projectName)
            views.setTextViewText(R.id.widget_status_badge, deployStatus)
            views.setTextViewText(R.id.widget_last_updated, VeroWidgetUtils.relativeTime(lastUpdated))

            val noProject = VeroWidgetUtils.getString(context, "vero_project_logs_id").isEmpty()
            if (noProject || logs.isEmpty()) {
                views.setViewVisibility(R.id.widget_no_logs, View.VISIBLE)
                views.setViewVisibility(R.id.widget_logs_container, View.GONE)
                views.setTextViewText(
                    R.id.widget_no_logs,
                    if (noProject) "Tap to configure widget" else "No recent logs"
                )
            } else {
                views.setViewVisibility(R.id.widget_no_logs, View.GONE)
                views.setViewVisibility(R.id.widget_logs_container, View.VISIBLE)

                for ((rowIndex, ids) in LOG_IDS.withIndex()) {
                    val (rowId, msgId, timeId) = ids
                    if (rowIndex < logs.size) {
                        val entry = logs[rowIndex]
                        val message = (entry["message"] as? String ?: "").take(60)
                        val timestamp = (entry["timestamp"] as? Int ?: 0).toLong()
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(msgId, message.ifEmpty { "—" })
                        views.setTextViewText(timeId, VeroWidgetUtils.formatTimestamp(timestamp))
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }
            }

            if (!isSubscribed) {
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
            }

            val openIntent = VeroWidgetUtils.openAppPendingIntent(
                context, "vero://widget/configure?type=logs"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
