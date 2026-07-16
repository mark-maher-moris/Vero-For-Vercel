package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.*
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class AnalyticsLargeWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.e("AnalyticsLargeWidget", "onUpdate called with ${appWidgetIds.size} widget IDs")
        val pending = goAsync()
        Thread {
            try {
                for (id in appWidgetIds) {
                    try {
                        updateWidget(context, appWidgetManager, id)
                    } catch (e: Exception) {
                        Log.e("AnalyticsLargeWidget", "Error updating widget $id", e)
                    }
                }
            } catch (e: Exception) {
                Log.e("AnalyticsLargeWidget", "Error in onUpdate thread", e)
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
            try {
                Log.e("AnalyticsLargeWidget", "updateWidget called for widget ID: $appWidgetId")
                val views = RemoteViews(context.packageName, R.layout.widget_analytics_large)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)
            val isDemoMode = VeroWidgetUtils.isDemoMode(context)
            val analyticsEnabled = VeroWidgetUtils.getBoolean(context, "vero_analytics_enabled", true)

            val projectName = VeroWidgetUtils.getProjectName(
                context, "vero_analytics_project_name", "Select Project"
            )
            val visitors24h = VeroWidgetUtils.getInt(context, "vero_analytics_visitors_24h")
            val bounceRate = VeroWidgetUtils.getInt(context, "vero_analytics_bounce_rate")
            val lastUpdated = VeroWidgetUtils.getString(context, "vero_last_updated")
            val sourcesJson = VeroWidgetUtils.getString(context, "vero_analytics_sources")
            val sources = if (sourcesJson.isNotEmpty()) VeroWidgetUtils.parseJsonArray(sourcesJson) else emptyList()
            val timeseriesJson = VeroWidgetUtils.getString(context, "vero_analytics_30day_timeseries")

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

                // Draw 30-day chart
                val timeseries = if (timeseriesJson.isNotEmpty()) VeroWidgetUtils.parseJsonArray(timeseriesJson) else emptyList()
                if (timeseries.isNotEmpty()) {
                    val chartBitmap = drawChart(timeseries)
                    views.setImageViewBitmap(R.id.widget_analytics_chart, chartBitmap)
                }
            }

            views.setViewVisibility(
                R.id.widget_lock_overlay,
                if (!isSubscribed && !isDemoMode) View.VISIBLE else View.GONE
            )

            val openIntent = VeroWidgetUtils.openAppPendingIntent(
                context, "vero://widget/configure?type=analytics"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.e("AnalyticsLargeWidget", "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e("AnalyticsLargeWidget", "Error in updateWidget for widget $appWidgetId", e)
            }
        }

        private fun drawChart(data: List<Map<String, Any>>): Bitmap {
            val width = 400
            val height = 200
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            // Background
            canvas.drawColor(Color.TRANSPARENT)

            if (data.isEmpty()) return bitmap

            // Extract values
            val values = data.mapNotNull { it["value"] as? Number }.map { it.toInt() }
            if (values.isEmpty()) return bitmap

            val maxValue = values.maxOrNull() ?: 1
            val minValue = 0
            val range = (maxValue - minValue).takeIf { it > 0 } ?: 1
            val denominator = (values.size - 1).takeIf { it > 0 } ?: 1

            // Chart dimensions
            val padding = 8f
            val chartWidth = width - (padding * 2)
            val chartHeight = height - (padding * 2)

            // Draw line chart
            val paint = Paint().apply {
                color = Color.parseColor("#4A9EFF")
                style = Paint.Style.STROKE
                strokeWidth = 3f
                isAntiAlias = true
                strokeCap = Paint.Cap.ROUND
            }

            val fillPaint = Paint().apply {
                color = Color.parseColor("#4A9EFF")
                style = Paint.Style.FILL
                alpha = 30
                isAntiAlias = true
            }

            val points = values.mapIndexed { index, value ->
                val x = padding + (index.toFloat() / denominator) * chartWidth
                val y = padding + chartHeight - ((value.toFloat() - minValue) / range) * chartHeight
                PointF(x, y)
            }

            // Draw fill under the line
            val fillPath = Path().apply {
                moveTo(padding, padding + chartHeight)
                points.forEach { point -> lineTo(point.x, point.y) }
                lineTo(padding + chartWidth, padding + chartHeight)
                close()
            }
            canvas.drawPath(fillPath, fillPaint)

            // Draw the line
            val linePath = Path().apply {
                if (points.isNotEmpty()) {
                    moveTo(points[0].x, points[0].y)
                    for (i in 1 until points.size) {
                        lineTo(points[i].x, points[i].y)
                    }
                }
            }
            canvas.drawPath(linePath, paint)

            return bitmap
        }
    }
}
