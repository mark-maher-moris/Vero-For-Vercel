package com.buildagon.vero

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object VeroWidgetUtils {

    private const val PREFS_NAME = "FlutterSharedPreferences"

    fun getPrefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getString(context: Context, key: String, default: String = ""): String =
        getPrefs(context).getString("flutter.$key", default) ?: default

    fun getBoolean(context: Context, key: String, default: Boolean = false): Boolean =
        getPrefs(context).getBoolean("flutter.$key", default)

    fun getInt(context: Context, key: String, default: Int = 0): Int {
        val prefs = getPrefs(context)
        return try {
            prefs.getInt("flutter.$key", default)
        } catch (_: ClassCastException) {
            try {
                prefs.getLong("flutter.$key", default.toLong()).toInt()
            } catch (_: Exception) {
                default
            }
        }
    }

    fun isSubscribed(context: Context): Boolean =
        getBoolean(context, "vero_is_subscribed", false)

    fun getApiToken(context: Context): String =
        getString(context, "vero_api_token")

    fun getTeamId(context: Context): String? {
        val t = getString(context, "vero_team_id")
        return if (t.isEmpty()) null else t
    }

    fun parseJsonArray(json: String): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val map = mutableMapOf<String, Any>()
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    map[k] = obj.get(k)
                }
                result.add(map)
            }
        } catch (_: Exception) {}
        return result
    }

    fun formatTimestamp(epochMs: Long): String {
        if (epochMs <= 0) return ""
        return try {
            val sdf = SimpleDateFormat("HH:mm:ss", Locale.US)
            sdf.format(Date(epochMs))
        } catch (_: Exception) {
            ""
        }
    }

    fun relativeTime(isoString: String): String {
        if (isoString.isEmpty()) return "Just now"
        return try {
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            sdf.isLenient = true
            val date = sdf.parse(isoString) ?: return "Recently"
            val diff = System.currentTimeMillis() - date.time
            when {
                diff < 60_000 -> "Just now"
                diff < 3_600_000 -> "${diff / 60_000}m ago"
                diff < 86_400_000 -> "${diff / 3_600_000}h ago"
                else -> "${diff / 86_400_000}d ago"
            }
        } catch (_: Exception) {
            "Recently"
        }
    }

    fun formatNumber(n: Int): String = when {
        n >= 1_000_000 -> "${n / 1_000_000}M"
        n >= 1_000 -> "${n / 1_000}K"
        else -> n.toString()
    }

    fun openAppPendingIntent(context: Context, uri: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(uri)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, uri.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun logLevelColor(level: String): Int = when (level.lowercase()) {
        "error", "fatal" -> android.graphics.Color.parseColor("#FF4F4F")
        "warn", "warning" -> android.graphics.Color.parseColor("#F5A623")
        "info" -> android.graphics.Color.parseColor("#4A9EFF")
        else -> android.graphics.Color.parseColor("#A0A0A0")
    }

    fun statusColor(state: String): Int = when (state.uppercase()) {
        "READY" -> android.graphics.Color.parseColor("#50E3C2")
        "ERROR", "CANCELED" -> android.graphics.Color.parseColor("#FF4F4F")
        "BUILDING", "INITIALIZING" -> android.graphics.Color.parseColor("#F5A623")
        else -> android.graphics.Color.parseColor("#888888")
    }

    fun getProjectName(context: Context, key: String, fallback: String): String {
        val name = getString(context, key)
        return if (name.isEmpty()) fallback else name
    }

    fun getProjectsList(context: Context): List<Pair<String, String>> {
        val json = getString(context, "vero_projects_json")
        if (json.isEmpty()) return emptyList()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).mapNotNull { i ->
                val obj = arr.optJSONObject(i) ?: return@mapNotNull null
                val id = obj.optString("id")
                val name = obj.optString("name")
                if (id.isNotEmpty()) Pair(id, name) else null
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
