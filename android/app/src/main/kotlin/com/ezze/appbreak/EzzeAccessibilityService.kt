package com.ezze.appbreak

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class EzzeAccessibilityService : AccessibilityService() {

    companion object {
        var isServiceRunning = false
            private set
        var currentForegroundPackage: String? = null
            private set
        var foregroundListener: ((String) -> Unit)? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        EzzeRestrictionManager.init(applicationContext)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // Skip Ezze Break itself
        if (packageName == "com.ezze.break") {
            return
        }

        // Never restrict critical system utilities, settings or dialers
        if (packageName == "com.android.settings" ||
            packageName == "com.google.android.settings" ||
            packageName == "com.android.dialer" ||
            packageName == "com.google.android.dialer" ||
            packageName == "com.android.packageinstaller" ||
            packageName == "com.google.android.packageinstaller" ||
            packageName.contains("systemui")
        ) {
            return
        }

        currentForegroundPackage = packageName
        foregroundListener?.invoke(packageName)

        // Check if package is marked as restricted
        if (EzzeRestrictionManager.isRestricted(packageName)) {
            val reason = EzzeRestrictionManager.getReason(packageName)
            val intent = Intent(this, RestrictionActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(RestrictionActivity.EXTRA_PACKAGE_NAME, packageName)
                putExtra(RestrictionActivity.EXTRA_REASON, reason)
            }
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Accessibility service interrupted
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
    }
}
