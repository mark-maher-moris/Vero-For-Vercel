package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class LogsLargeWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.e("LogsLargeWidget", "onUpdate called with ${appWidgetIds.size} widget IDs")
        val pending = goAsync()
        Thread {
            try {
                for (id in appWidgetIds) {
                    try {
                        updateWidget(context, appWidgetManager, id)
                    } catch (e: Exception) {
                        Log.e("LogsLargeWidget", "Error updating widget $id", e)
                    }
                }
            } catch (e: Exception) {
                Log.e("LogsLargeWidget", "Error in onUpdate thread", e)
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
            Triple(R.id.log_row_5, R.id.log_msg_5, R.id.log_time_5),
            Triple(R.id.log_row_6, R.id.log_msg_6, R.id.log_time_6),
            Triple(R.id.log_row_7, R.id.log_msg_7, R.id.log_time_7),
            Triple(R.id.log_row_8, R.id.log_msg_8, R.id.log_time_8),
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                Log.e("LogsLargeWidget", "updateWidget called for widget ID: $appWidgetId")
                val views = RemoteViews(context.packageName, R.layout.widget_logs_large)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)
            val isDemoMode = VeroWidgetUtils.isDemoMode(context)

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
                        val message = (entry["message"] as? String ?: "").take(80)
                        val timestamp = (entry["timestamp"] as? Int ?: 0).toLong()
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(msgId, message.ifEmpty { "—" })
                        views.setTextViewText(timeId, VeroWidgetUtils.formatTimestamp(timestamp))
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }
            }

            views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)

            val openIntent = VeroWidgetUtils.openAppPendingIntent(
                context, "vero://widget/configure?type=logs"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.e("LogsLargeWidget", "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e("LogsLargeWidget", "Error in updateWidget for widget $appWidgetId", e)
            }
        }
    }
}
