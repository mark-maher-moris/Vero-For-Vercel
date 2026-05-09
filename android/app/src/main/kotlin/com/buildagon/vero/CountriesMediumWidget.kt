package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews

class CountriesMediumWidget : AppWidgetProvider() {

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
        private val COUNTRY_IDS = listOf(
            Triple(R.id.country_row_1, R.id.country_name_1, R.id.country_count_1),
            Triple(R.id.country_row_2, R.id.country_name_2, R.id.country_count_2),
            Triple(R.id.country_row_3, R.id.country_name_3, R.id.country_count_3),
            Triple(R.id.country_row_4, R.id.country_name_4, R.id.country_count_4),
            Triple(R.id.country_row_5, R.id.country_name_5, R.id.country_count_5),
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_countries_medium)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)

            val projectName = VeroWidgetUtils.getProjectName(
                context, "vero_countries_project_name", "Select Project"
            )
            val lastUpdated = VeroWidgetUtils.getString(context, "vero_last_updated")
            val countriesJson = VeroWidgetUtils.getString(context, "vero_countries_data")
            val countries = if (countriesJson.isNotEmpty()) VeroWidgetUtils.parseJsonArray(countriesJson) else emptyList()

            views.setTextViewText(R.id.widget_project_name, projectName)
            views.setTextViewText(R.id.widget_last_updated, VeroWidgetUtils.relativeTime(lastUpdated))

            val noProject = VeroWidgetUtils.getString(context, "vero_project_countries_id").isEmpty()
            if (noProject || countries.isEmpty()) {
                views.setViewVisibility(R.id.widget_no_data, View.VISIBLE)
                views.setViewVisibility(R.id.widget_countries_container, View.GONE)
                views.setTextViewText(
                    R.id.widget_no_data,
                    if (noProject) "Tap to configure widget" else "No traffic data"
                )
            } else {
                views.setViewVisibility(R.id.widget_no_data, View.GONE)
                views.setViewVisibility(R.id.widget_countries_container, View.VISIBLE)

                for ((idx, ids) in COUNTRY_IDS.withIndex()) {
                    val (rowId, nameId, countId) = ids
                    if (idx < countries.size) {
                        val entry = countries[idx]
                        val name = (entry["name"] as? String ?: entry["code"] as? String ?: "Unknown").take(18)
                        val visitors = entry["visitors"]?.toString()?.toIntOrNull() ?: 0
                        val pct = entry["percentage"]?.toString() ?: "0"
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(nameId, name)
                        views.setTextViewText(countId, "${VeroWidgetUtils.formatNumber(visitors)} ($pct%)")
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
                context, "vero://widget/configure?type=countries"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
