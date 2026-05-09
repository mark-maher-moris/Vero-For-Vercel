package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews

class AnalyticsLargeWidget : AppWidgetProvider() {

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
        private val SOURCE_IDS = listOf(
            Triple(R.id.source_row_1, R.id.source_name_1, R.id.source_count_1),
            Triple(R.id.source_row_2, R.id.source_name_2, R.id.source_count_2),
            Triple(R.id.source_row_3, R.id.source_name_3, R.id.source_count_3),
            Triple(R.id.source_row_4, R.id.source_name_4, R.id.source_count_4),
            Triple(R.id.source_row_5, R.id.source_name_5, R.id.source_count_5),
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_analytics_large)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)
            val analyticsEnabled = VeroWidgetUtils.getBoolean(context, "vero_analytics_enabled", true)

            val projectName = VeroWidgetUtils.getProjectName(
                context, "vero_analytics_project_name", "Select Project"
            )
            val visitors24h = VeroWidgetUtils.getInt(context, "vero_analytics_visitors_24h")
            val bounceRate = VeroWidgetUtils.getInt(context, "vero_analytics_bounce_rate")
            val lastUpdated = VeroWidgetUtils.getString(context, "vero_last_updated")
            val sourcesJson = VeroWidgetUtils.getString(context, "vero_analytics_sources")
            val sources = if (sourcesJson.isNotEmpty()) VeroWidgetUtils.parseJsonArray(sourcesJson) else emptyList()

            views.setTextViewText(R.id.widget_project_name, projectName)
            views.setTextViewText(R.id.widget_visitors_24h, VeroWidgetUtils.formatNumber(visitors24h))
            views.setTextViewText(R.id.widget_bounce_rate, "$bounceRate%")
            views.setTextViewText(R.id.widget_last_updated, VeroWidgetUtils.relativeTime(lastUpdated))

            val noProject = VeroWidgetUtils.getString(context, "vero_project_analytics_id").isEmpty()

            if (!analyticsEnabled) {
                views.setViewVisibility(R.id.widget_analytics_disabled, View.VISIBLE)
                views.setViewVisibility(R.id.widget_analytics_content, View.GONE)
            } else if (noProject) {
                views.setViewVisibility(R.id.widget_analytics_disabled, View.GONE)
                views.setViewVisibility(R.id.widget_analytics_content, View.GONE)
                views.setViewVisibility(R.id.widget_no_project, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_analytics_disabled, View.GONE)
                views.setViewVisibility(R.id.widget_no_project, View.GONE)
                views.setViewVisibility(R.id.widget_analytics_content, View.VISIBLE)

                for ((idx, ids) in SOURCE_IDS.withIndex()) {
                    val (rowId, nameId, countId) = ids
                    if (idx < sources.size) {
                        val src = sources[idx]
                        val sourceName = (src["source"] as? String ?: "Direct").take(22)
                        val count = src["visitors"]?.toString() ?: "0"
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(nameId, sourceName)
                        views.setTextViewText(countId, VeroWidgetUtils.formatNumber(count.toIntOrNull() ?: 0))
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
                context, "vero://widget/configure?type=analytics"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
