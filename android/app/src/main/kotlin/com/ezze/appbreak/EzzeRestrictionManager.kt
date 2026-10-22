package com.ezze.appbreak

import android.content.Context
import android.content.SharedPreferences
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object EzzeRestrictionManager {
    private const val PREFS_NAME = "ezze_break_restrictions"
    private const val KEY_RESTRICTED_PACKAGES = "restricted_packages"
    private const val KEY_LAST_DATE = "last_date_key"
    private const val PREF_USAGE_PREFIX = "usage_today_"

    // In-memory cache: packageName -> reason ("break" or "limit_over")
    private val restrictedApps = mutableMapOf<String, String>()

    data class AppRuleConfig(
        val packageName: String,
        val sessionLimitSeconds: Int = 20 * 60,
        val dailyBudgetSeconds: Int = 60 * 60,
        val breakDurationSeconds: Int = 5 * 60,
        var additionalSeconds: Int = 0,
        var isMonitored: Boolean = true
    )

    private val monitoredRules = mutableMapOf<String, AppRuleConfig>()
    private val dailyUsageSeconds = mutableMapOf<String, Int>()

    var continuousSessionSeconds: Int = 0
    var activeMonitoredPackage: String? = null

    fun getTodayDateKey(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    fun init(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = getTodayDateKey()
        val lastDate = prefs.getString(KEY_LAST_DATE, "") ?: ""

        synchronized(restrictedApps) {
            restrictedApps.clear()
            if (lastDate == today) {
                // Same day: restore active restrictions
                val entries = prefs.getStringSet(KEY_RESTRICTED_PACKAGES, emptySet()) ?: emptySet()
                for (entry in entries) {
                    val parts = entry.split(":")
                    if (parts.size >= 2) {
                        restrictedApps[parts[0]] = parts[1]
                    } else if (parts.isNotEmpty()) {
                        restrictedApps[parts[0]] = "break"
                    }
                }
                // Restore today's cached usage
                val allPrefs = prefs.all
                for ((key, value) in allPrefs) {
                    if (key.startsWith(PREF_USAGE_PREFIX) && value is Int) {
                        val pkg = key.removePrefix(PREF_USAGE_PREFIX)
                        dailyUsageSeconds[pkg] = value
                    }
                }
            } else {
                // Past 12:00 AM midnight! Reset all restrictions and daily stats for fresh new day
                performMidnightReset(context, today)
            }
        }
    }

    /**
     * Checks if calendar day has crossed midnight (12:00 AM).
     * If so, clears all restrictions and resets daily usage to 0 immediately.
     */
    fun checkDateRollover(context: Context): Boolean {
        val today = getTodayDateKey()
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastDate = prefs.getString(KEY_LAST_DATE, "") ?: ""
        if (lastDate != today) {
            performMidnightReset(context, today)
            return true
        }
        return false
    }

    private fun performMidnightReset(context: Context, newDateKey: String) {
        synchronized(restrictedApps) {
            restrictedApps.clear()
            dailyUsageSeconds.clear()
            continuousSessionSeconds = 0
            activeMonitoredPackage = null

            // Reset rules additionalSeconds
            for (rule in monitoredRules.values) {
                rule.additionalSeconds = 0
            }
        }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        // Clear all usage keys
        for (key in prefs.all.keys) {
            if (key.startsWith(PREF_USAGE_PREFIX) || key == KEY_RESTRICTED_PACKAGES) {
                editor.remove(key)
            }
        }
        editor.putString(KEY_LAST_DATE, newDateKey)
        editor.putStringSet(KEY_RESTRICTED_PACKAGES, emptySet())
        editor.apply()
    }

    fun syncRules(context: Context, rulesList: List<Map<String, Any>>) {
        synchronized(monitoredRules) {
            monitoredRules.clear()
            for (map in rulesList) {
                val pkg = map["packageName"] as? String ?: continue
                val sessionLimitMins = (map["sessionLimitMinutes"] as? Number)?.toInt() ?: 20
                val dailyBudgetMins = (map["dailyBudgetMinutes"] as? Number)?.toInt() ?: 60
                val breakDurationMins = (map["breakDurationMinutes"] as? Number)?.toInt() ?: 5
                val addSec = (map["additionalSeconds"] as? Number)?.toInt() ?: 0
                val isMonitored = (map["isMonitored"] as? Boolean) ?: true

                monitoredRules[pkg] = AppRuleConfig(
                    packageName = pkg,
                    sessionLimitSeconds = sessionLimitMins * 60,
                    dailyBudgetSeconds = dailyBudgetMins * 60,
                    breakDurationSeconds = breakDurationMins * 60,
                    additionalSeconds = addSec,
                    isMonitored = isMonitored
                )
            }
        }
    }

    fun getRule(packageName: String): AppRuleConfig? {
        synchronized(monitoredRules) {
            return monitoredRules[packageName]
        }
    }

    fun isMonitored(packageName: String): Boolean {
        synchronized(monitoredRules) {
            val rule = monitoredRules[packageName]
            return rule != null && rule.isMonitored
        }
    }

    fun getDailyUsage(packageName: String): Int {
        synchronized(dailyUsageSeconds) {
            return dailyUsageSeconds[packageName] ?: 0
        }
    }

    fun setDailyUsage(packageName: String, seconds: Int) {
        synchronized(dailyUsageSeconds) {
            dailyUsageSeconds[packageName] = seconds
        }
    }

    fun getAllDailyUsage(): Map<String, Int> {
        synchronized(dailyUsageSeconds) {
            return HashMap(dailyUsageSeconds)
        }
    }

    fun recordTick(context: Context, packageName: String) {
        synchronized(dailyUsageSeconds) {
            val current = dailyUsageSeconds[packageName] ?: 0
            dailyUsageSeconds[packageName] = current + 1
        }
        continuousSessionSeconds++

        // Persist every 10 seconds to save I/O
        if (continuousSessionSeconds % 10 == 0) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val current = dailyUsageSeconds[packageName] ?: 0
            prefs.edit().putInt(PREF_USAGE_PREFIX + packageName, current).apply()
        }
    }

    fun releaseBreak(context: Context, packageName: String) {
        synchronized(restrictedApps) {
            if (restrictedApps[packageName] == "break") {
                restrictedApps.remove(packageName)
            }
            continuousSessionSeconds = 0
        }
        persist(context)
    }

    fun grantOverride(context: Context, packageName: String, extraSeconds: Int) {
        synchronized(monitoredRules) {
            val rule = monitoredRules[packageName]
            if (rule != null) {
                rule.additionalSeconds += extraSeconds
            }
        }
        synchronized(restrictedApps) {
            if (restrictedApps[packageName] == "limit_over") {
                restrictedApps.remove(packageName)
            }
        }
        persist(context)
    }

    fun setRestriction(context: Context, packageName: String, reason: String) {
        synchronized(restrictedApps) {
            restrictedApps[packageName] = reason
        }
        persist(context)
    }

    fun clearRestriction(context: Context, packageName: String) {
        synchronized(restrictedApps) {
            restrictedApps.remove(packageName)
        }
        persist(context)
    }

    fun updateAllRestrictions(context: Context, restrictions: Map<String, String>) {
        synchronized(restrictedApps) {
            restrictedApps.clear()
            restrictedApps.putAll(restrictions)
        }
        persist(context)
    }

    fun isRestricted(packageName: String): Boolean {
        synchronized(restrictedApps) {
            return restrictedApps.containsKey(packageName)
        }
    }

    fun getReason(packageName: String): String {
        synchronized(restrictedApps) {
            return restrictedApps[packageName] ?: "break"
        }
    }

    private fun persist(context: Context) {
        val set = mutableSetOf<String>()
        synchronized(restrictedApps) {
            for ((pkg, reason) in restrictedApps) {
                set.add("$pkg:$reason")
            }
        }
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_RESTRICTED_PACKAGES, set).apply()
    }
}
