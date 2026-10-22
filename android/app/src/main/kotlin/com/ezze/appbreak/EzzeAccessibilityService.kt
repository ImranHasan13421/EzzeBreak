package com.ezze.appbreak

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class EzzeAccessibilityService : AccessibilityService() {

    companion object {
        var isServiceRunning = false
            private set
        var currentForegroundPackage: String? = null
            private set
        var foregroundListener: ((String) -> Unit)? = null
        var tickListener: ((String, Int, Int) -> Unit)? = null
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isTickerStarted = false

    private val tickerRunnable = object : Runnable {
        override fun run() {
            try {
                onSecondTick()
            } catch (_: Exception) {}
            handler.postDelayed(this, 1000)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        EzzeRestrictionManager.init(applicationContext)

        if (!isTickerStarted) {
            isTickerStarted = true
            handler.post(tickerRunnable)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // Skip Ezze Break itself and its activities
        if (packageName == applicationContext.packageName || packageName == "com.ezze.break") {
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
            currentForegroundPackage = packageName
            EzzeRestrictionManager.continuousSessionSeconds = 0
            return
        }

        val prevPackage = currentForegroundPackage
        if (prevPackage != packageName) {
            currentForegroundPackage = packageName
            // Switching between apps resets continuous session timer
            EzzeRestrictionManager.continuousSessionSeconds = 0
            foregroundListener?.invoke(packageName)
        }

        // Check if package is already marked as restricted
        if (EzzeRestrictionManager.isRestricted(packageName)) {
            val reason = EzzeRestrictionManager.getReason(packageName)
            launchRestriction(packageName, reason)
        }
    }

    private fun onSecondTick() {
        // 1. Midnight rollover check
        EzzeRestrictionManager.checkDateRollover(applicationContext)

        val pkg = currentForegroundPackage ?: return

        // Skip Ezze Break itself or system apps
        if (pkg == applicationContext.packageName || pkg == "com.ezze.break") {
            return
        }

        // Check if package is monitored
        if (!EzzeRestrictionManager.isMonitored(pkg)) {
            return
        }

        // 2. If already restricted, enforce restriction overlay
        if (EzzeRestrictionManager.isRestricted(pkg)) {
            val reason = EzzeRestrictionManager.getReason(pkg)
            launchRestriction(pkg, reason)
            return
        }

        // 3. Increment counters
        EzzeRestrictionManager.recordTick(applicationContext, pkg)

        val dailyUsed = EzzeRestrictionManager.getDailyUsage(pkg)
        val continuousUsed = EzzeRestrictionManager.continuousSessionSeconds

        // Notify Flutter if attached
        tickListener?.invoke(pkg, dailyUsed, continuousUsed)

        val rule = EzzeRestrictionManager.getRule(pkg) ?: return

        // 4. Check continuous session break limit
        if (rule.sessionLimitSeconds > 0 && continuousUsed >= rule.sessionLimitSeconds) {
            EzzeRestrictionManager.setRestriction(applicationContext, pkg, "break")
            launchRestriction(pkg, "break")
            return
        }

        // 5. Check daily budget limit
        val totalBudget = rule.dailyBudgetSeconds + rule.additionalSeconds
        if (totalBudget > 0 && dailyUsed >= totalBudget) {
            EzzeRestrictionManager.setRestriction(applicationContext, pkg, "limit_over")
            launchRestriction(pkg, "limit_over")
            return
        }
    }

    private fun launchRestriction(packageName: String, reason: String) {
        val intent = Intent(this, RestrictionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(RestrictionActivity.EXTRA_PACKAGE_NAME, packageName)
            putExtra(RestrictionActivity.EXTRA_REASON, reason)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        handler.removeCallbacks(tickerRunnable)
        isTickerStarted = false
    }
}
