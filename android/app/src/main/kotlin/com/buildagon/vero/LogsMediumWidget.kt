package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class LogsMediumWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.e("LogsMediumWidget", "onUpdate called with ${appWidgetIds.size} widget IDs")
        val pending = goAsync()
        Thread {
            try {
                for (id in appWidgetIds) {
                    try {
                        updateWidget(context, appWidgetManager, id)
                    } catch (e: Exception) {
                        Log.e("LogsMediumWidget", "Error updating widget $id", e)
                    }
                }
            } catch (e: Exception) {
                Log.e("LogsMediumWidget", "Error in onUpdate thread", e)
            } finally {
                pending.finish()
            }
        }.start()
    }

    companion object {
        private val LOG_IDS = listOf(
            Pair(R.id.log_row_1, R.id.log_msg_1),
            Pair(R.id.log_row_2, R.id.log_msg_2),
            Pair(R.id.log_row_3, R.id.log_msg_3),
            Pair(R.id.log_row_4, R.id.log_msg_4),
            Pair(R.id.log_row_5, R.id.log_msg_5),
            Pair(R.id.log_row_6, R.id.log_msg_6),
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                Log.e("LogsMediumWidget", "updateWidget called for widget ID: $appWidgetId")
                val views = RemoteViews(context.packageName, R.layout.widget_logs_medium)
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
            val statusColor = VeroWidgetUtils.statusColor(deployStatus)
            views.setTextColor(R.id.widget_status_badge, statusColor)
            views.setInt(
                R.id.widget_status_badge,
                "setBackgroundColor",
                VeroWidgetUtils.statusBackgroundColor(deployStatus),
            )
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
                    val (rowId, msgId) = ids
                    if (rowIndex < logs.size) {
                        val entry = logs[rowIndex]
                        val message = (entry["message"] as? String ?: "").take(60)
                        val level = entry["level"] as? String ?: entry["type"] as? String ?: "info"
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(msgId, message.ifEmpty { "—" })
                        views.setTextColor(msgId, VeroWidgetUtils.logLevelColor(level))
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }
            }

            views.setViewVisibility(
                R.id.widget_lock_overlay,
                if (!isSubscribed && !isDemoMode) View.VISIBLE else View.GONE
            )

            val openIntent = VeroWidgetUtils.openAppPendingIntent(
                context, "vero://widget/configure?type=logs&homeWidget=true"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.e("LogsMediumWidget", "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e("LogsMediumWidget", "Error in updateWidget for widget $appWidgetId", e)
            }
        }
    }
}
