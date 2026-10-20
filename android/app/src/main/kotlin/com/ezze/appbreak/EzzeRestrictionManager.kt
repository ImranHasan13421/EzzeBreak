package com.ezze.appbreak

import android.content.Context
import android.content.SharedPreferences

object EzzeRestrictionManager {
    private const val PREFS_NAME = "ezze_break_restrictions"
    private const val KEY_RESTRICTED_PACKAGES = "restricted_packages"

    // In-memory cache: packageName -> reason ("break" or "limit_over")
    private val restrictedApps = mutableMapOf<String, String>()

    fun init(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val entries = prefs.getStringSet(KEY_RESTRICTED_PACKAGES, emptySet()) ?: emptySet()
        synchronized(restrictedApps) {
            restrictedApps.clear()
            for (entry in entries) {
                val parts = entry.split(":")
                if (parts.size >= 2) {
                    restrictedApps[parts[0]] = parts[1]
                } else if (parts.isNotEmpty()) {
                    restrictedApps[parts[0]] = "break"
                }
            }
        }
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
