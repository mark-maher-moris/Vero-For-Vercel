package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.*
import android.view.View
import android.widget.RemoteViews

class UsersSmallWidget : AppWidgetProvider() {

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
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_users_small)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)
            val isDemoMode = VeroWidgetUtils.isDemoMode(context)

            val projectName = VeroWidgetUtils.getProjectName(
                context, "vero_users_project_name", "No project"
            )
            val total24h = VeroWidgetUtils.getInt(context, "vero_users_total_24h")
            val lastUpdated = VeroWidgetUtils.getString(context, "vero_last_updated")
            val timeseriesJson = VeroWidgetUtils.getString(context, "vero_users_timeseries")

            views.setTextViewText(R.id.widget_project_name, projectName)
            views.setTextViewText(R.id.widget_total_users, VeroWidgetUtils.formatNumber(total24h))
            views.setTextViewText(R.id.widget_last_updated, VeroWidgetUtils.relativeTime(lastUpdated))

            // Draw chart from timeseries data
            val timeseries = if (timeseriesJson.isNotEmpty()) VeroWidgetUtils.parseJsonArray(timeseriesJson) else emptyList()
            if (timeseries.isNotEmpty()) {
                val chartBitmap = drawChart(timeseries)
                views.setImageViewBitmap(R.id.widget_chart, chartBitmap)
            }

            val noProject = VeroWidgetUtils.getString(context, "vero_project_users_id").isEmpty()
            if (noProject) {
                views.setViewVisibility(R.id.widget_no_project, View.VISIBLE)
                views.setViewVisibility(R.id.widget_data_container, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_no_project, View.GONE)
                views.setViewVisibility(R.id.widget_data_container, View.VISIBLE)
            }

            views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)

            val openIntent = VeroWidgetUtils.openAppPendingIntent(
                context, "vero://widget/configure?type=users"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun drawChart(data: List<Map<String, Any>>): Bitmap {
            val width = 400
            val height = 160
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

            // Chart dimensions
            val padding = 8f
            val chartWidth = width - (padding * 2)
            val chartHeight = height - (padding * 2)

            // Draw line chart
            val paint = Paint().apply {
                color = Color.parseColor("#50E3C2")
                style = Paint.Style.STROKE
                strokeWidth = 4f
                isAntiAlias = true
                strokeCap = Paint.Cap.ROUND
            }

            val fillPaint = Paint().apply {
                color = Color.parseColor("#50E3C2")
                style = Paint.Style.FILL
                alpha = 40
                isAntiAlias = true
            }

            val points = values.mapIndexed { index, value ->
                val x = padding + (index.toFloat() / (values.size - 1)) * chartWidth
                val y = padding + chartHeight - ((value.toFloat() - minValue) / (maxValue - minValue)) * chartHeight
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
