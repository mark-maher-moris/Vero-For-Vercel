package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class CountriesMediumWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.e("CountriesMediumWidget", "onUpdate called with ${appWidgetIds.size} widget IDs")
        val pending = goAsync()
        Thread {
            try {
                for (id in appWidgetIds) {
                    try {
                        updateWidget(context, appWidgetManager, id)
                    } catch (e: Exception) {
                        Log.e("CountriesMediumWidget", "Error updating widget $id", e)
                    }
                }
            } catch (e: Exception) {
                Log.e("CountriesMediumWidget", "Error in onUpdate thread", e)
            } finally {
                pending.finish()
            }
        }.start()
    }

    companion object {
        private data class CountryRowIds(
            val rowId: Int,
            val flagId: Int,
            val nameId: Int,
            val countId: Int,
            val percentageId: Int,
        )

        private val COUNTRY_IDS = listOf(
            CountryRowIds(R.id.country_row_1, R.id.country_flag_1, R.id.country_name_1, R.id.country_count_1, R.id.country_percentage_1),
            CountryRowIds(R.id.country_row_2, R.id.country_flag_2, R.id.country_name_2, R.id.country_count_2, R.id.country_percentage_2),
            CountryRowIds(R.id.country_row_3, R.id.country_flag_3, R.id.country_name_3, R.id.country_count_3, R.id.country_percentage_3),
            CountryRowIds(R.id.country_row_4, R.id.country_flag_4, R.id.country_name_4, R.id.country_count_4, R.id.country_percentage_4),
            CountryRowIds(R.id.country_row_5, R.id.country_flag_5, R.id.country_name_5, R.id.country_count_5, R.id.country_percentage_5),
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                Log.e("CountriesMediumWidget", "updateWidget called for widget ID: $appWidgetId")
                val views = RemoteViews(context.packageName, R.layout.widget_countries_medium)
            val isSubscribed = VeroWidgetUtils.isSubscribed(context)
            val isDemoMode = VeroWidgetUtils.isDemoMode(context)

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
                    val rowId = ids.rowId
                    if (idx < countries.size) {
                        val entry = countries[idx]
                        val name = (entry["name"] as? String ?: entry["code"] as? String ?: "Unknown").take(18)
                        val code = entry["code"] as? String ?: ""
                        val visitors = entry["visitors"]?.toString()?.toIntOrNull() ?: 0
                        val pct = entry["percentage"]?.toString() ?: "0"
                        views.setViewVisibility(rowId, View.VISIBLE)
                        views.setTextViewText(ids.flagId, VeroWidgetUtils.flagEmoji(code))
                        views.setTextViewText(ids.nameId, name)
                        views.setTextViewText(ids.countId, VeroWidgetUtils.formatNumber(visitors))
                        views.setTextViewText(ids.percentageId, "$pct%")
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
                context, "vero://widget/configure?type=countries&homeWidget=true"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.e("CountriesMediumWidget", "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e("CountriesMediumWidget", "Error in updateWidget for widget $appWidgetId", e)
            }
        }
    }
}
