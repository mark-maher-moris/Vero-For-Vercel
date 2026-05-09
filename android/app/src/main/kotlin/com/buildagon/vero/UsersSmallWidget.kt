package com.buildagon.vero

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
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

            val projectName = VeroWidgetUtils.getProjectName(
                context, "vero_users_project_name", "No project"
            )
            val total24h = VeroWidgetUtils.getInt(context, "vero_users_total_24h")
            val lastHour = VeroWidgetUtils.getInt(context, "vero_users_last_hour")
            val bounceRate = VeroWidgetUtils.getInt(context, "vero_users_bounce_rate")
            val lastUpdated = VeroWidgetUtils.getString(context, "vero_last_updated")

            views.setTextViewText(R.id.widget_project_name, projectName)
            views.setTextViewText(R.id.widget_total_users, VeroWidgetUtils.formatNumber(total24h))
            views.setTextViewText(R.id.widget_online_users, VeroWidgetUtils.formatNumber(lastHour))
            views.setTextViewText(R.id.widget_bounce_rate, "$bounceRate%")
            views.setTextViewText(R.id.widget_last_updated, VeroWidgetUtils.relativeTime(lastUpdated))

            val noProject = VeroWidgetUtils.getString(context, "vero_project_users_id").isEmpty()
            if (noProject) {
                views.setViewVisibility(R.id.widget_no_project, View.VISIBLE)
                views.setViewVisibility(R.id.widget_data_container, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_no_project, View.GONE)
                views.setViewVisibility(R.id.widget_data_container, View.VISIBLE)
            }

            if (!isSubscribed) {
                views.setViewVisibility(R.id.widget_lock_overlay, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_lock_overlay, View.GONE)
            }

            val openIntent = VeroWidgetUtils.openAppPendingIntent(
                context, "vero://widget/configure?type=users"
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
