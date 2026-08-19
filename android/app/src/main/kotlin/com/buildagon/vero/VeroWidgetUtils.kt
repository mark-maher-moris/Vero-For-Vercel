package com.buildagon.vero

import android.app.PendingIntent
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.time.Instant
import java.util.Date
import java.util.Locale

object VeroWidgetUtils {

    // home_widget stores saveWidgetData values in this preferences file using
    // the exact key passed from Dart (without the SharedPreferences
    // `flutter.` prefix). Keep the Flutter preferences fallback for data
    // written by older app versions.
    private const val HOME_WIDGET_PREFS_NAME = "HomeWidgetPreferences"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"

    fun getPrefs(context: Context): SharedPreferences =
        context.getSharedPreferences(HOME_WIDGET_PREFS_NAME, Context.MODE_PRIVATE)

    private fun getRawValue(context: Context, key: String): Any? {
        val candidates = arrayOf(key, "flutter.$key")
        val preferenceFiles = arrayOf(
            getPrefs(context),
            context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE),
        )

        for (preferences in preferenceFiles) {
            for (candidate in candidates) {
                if (preferences.contains(candidate)) {
                    return preferences.all[candidate]
                }
            }
        }
        return null
    }

    fun getString(context: Context, key: String, default: String = ""): String =
        when (val value = getRawValue(context, key)) {
            is String -> value
            null -> default
            else -> value.toString()
        }

    fun getBoolean(context: Context, key: String, default: Boolean = false): Boolean =
        when (val value = getRawValue(context, key)) {
            is Boolean -> value
            is Number -> value.toInt() != 0
            is String -> value.equals("true", ignoreCase = true)
            else -> default
        }

    fun getInt(context: Context, key: String, default: Int = 0): Int {
        return when (val value = getRawValue(context, key)) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull() ?: default
            else -> default
        }
    }

    fun isSubscribed(context: Context): Boolean =
        getBoolean(context, "vero_is_subscribed", false)

    fun isDemoMode(context: Context): Boolean =
        getBoolean(context, "vero_is_demo_mode", false)

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
            val date = Instant.parse(isoString)
            val diff = System.currentTimeMillis() - date.toEpochMilli()
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

    fun flagEmoji(countryCode: String): String {
        val code = countryCode.trim().uppercase(Locale.US)
        if (code.length != 2 || code.any { it !in 'A'..'Z' }) return ""
        val result = StringBuilder()
        code.forEach { character ->
            result.append(Character.toChars(127397 + character.code))
        }
        return result.toString()
    }

    fun openAppPendingIntent(context: Context, uri: String): PendingIntent {
        return HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(uri)
        )
    }

    fun logLevelColor(level: String): Int = when (level.lowercase()) {
        "error", "err", "fatal" -> android.graphics.Color.parseColor("#FF4F4F")
        "warn", "warning" -> android.graphics.Color.parseColor("#F5A623")
        "success", "ready" -> android.graphics.Color.parseColor("#50E3C2")
        "debug", "trace" -> android.graphics.Color.parseColor("#9B8CFF")
        "info" -> android.graphics.Color.parseColor("#4A9EFF")
        else -> android.graphics.Color.parseColor("#E6E6E6")
    }

    fun statusColor(state: String): Int = when (state.uppercase()) {
        "READY" -> android.graphics.Color.parseColor("#50E3C2")
        "ERROR", "CANCELED" -> android.graphics.Color.parseColor("#FF4F4F")
        "BUILDING", "INITIALIZING", "QUEUED" -> android.graphics.Color.parseColor("#F5A623")
        else -> android.graphics.Color.parseColor("#888888")
    }

    fun statusBackgroundColor(state: String): Int {
        val color = statusColor(state)
        return android.graphics.Color.argb(
            31,
            android.graphics.Color.red(color),
            android.graphics.Color.green(color),
            android.graphics.Color.blue(color),
        )
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
