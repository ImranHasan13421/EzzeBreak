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
        var instance: EzzeAccessibilityService? = null
            private set
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isTickerStarted = false
    private var lastRestrictionLaunchTime = 0L

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
        instance = this
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

        // 1. Skip and track Ezze Break itself and its activities
        if (packageName == applicationContext.packageName || packageName == "com.ezze.break") {
            currentForegroundPackage = packageName
            EzzeRestrictionManager.continuousSessionSeconds = 0
            foregroundListener?.invoke(packageName)
            return
        }

        // 2. Never restrict critical system utilities, settings or dialers
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
            foregroundListener?.invoke(packageName)
            return
        }

        val prevPackage = currentForegroundPackage
        if (prevPackage != packageName) {
            currentForegroundPackage = packageName
            // Switching between apps resets continuous session timer
            EzzeRestrictionManager.continuousSessionSeconds = 0
            foregroundListener?.invoke(packageName)
        }

        // 3. If package is restricted, block access immediately and return home
        if (EzzeRestrictionManager.isRestricted(packageName)) {
            val reason = EzzeRestrictionManager.getReason(packageName)
            performGlobalAction(GLOBAL_ACTION_HOME)
            launchRestriction(packageName, reason)
        }
    }

    private fun onSecondTick() {
        // 1. Midnight rollover check
        EzzeRestrictionManager.checkDateRollover(applicationContext)

        val pkg = currentForegroundPackage ?: return

        // Never count time or restrict Ezze Break itself or system apps
        if (pkg == applicationContext.packageName ||
            pkg == "com.ezze.break" ||
            pkg.contains("systemui") ||
            pkg == "com.android.settings" ||
            pkg == "com.google.android.settings" ||
            pkg == "com.android.dialer" ||
            pkg == "com.google.android.dialer"
        ) {
            return
        }

        // Check if package is monitored
        if (!EzzeRestrictionManager.isMonitored(pkg)) {
            return
        }

        // 2. If already marked restricted, enforce block immediately and close app
        if (EzzeRestrictionManager.isRestricted(pkg)) {
            val reason = EzzeRestrictionManager.getReason(pkg)
            performGlobalAction(GLOBAL_ACTION_HOME)
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

        // 4. Daily budget limit check (Highest priority: daily budget exhaustion)
        val totalBudget = rule.dailyBudgetSeconds + rule.additionalSeconds
        if (totalBudget > 0 && dailyUsed >= totalBudget) {
            EzzeRestrictionManager.setRestriction(applicationContext, pkg, "limit_over")
            performGlobalAction(GLOBAL_ACTION_HOME)
            launchRestriction(pkg, "limit_over")
            return
        }

        // 5. Continuous session break limit check (e.g. 15m continuous usage)
        if (rule.sessionLimitSeconds > 0 && continuousUsed >= rule.sessionLimitSeconds) {
            EzzeRestrictionManager.setRestriction(applicationContext, pkg, "break")
            performGlobalAction(GLOBAL_ACTION_HOME)
            launchRestriction(pkg, "break")
            return
        }
    }

    fun launchRestriction(packageName: String, reason: String) {
        val now = System.currentTimeMillis()
        if (now - lastRestrictionLaunchTime < 1200) {
            return
        }
        lastRestrictionLaunchTime = now

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
        instance = null
        isServiceRunning = false
        handler.removeCallbacks(tickerRunnable)
        isTickerStarted = false
    }
}
