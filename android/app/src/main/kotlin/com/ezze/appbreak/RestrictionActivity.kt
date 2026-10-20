package com.ezze.appbreak

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class RestrictionActivity : Activity() {

    companion object {
        const val EXTRA_PACKAGE_NAME = "restricted_package_name"
        const val EXTRA_REASON = "restriction_reason" // "break" or "limit_over"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val targetPackage = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        val reason = intent.getStringExtra(EXTRA_REASON) ?: "break"

        // Fetch target app metadata
        val pm = packageManager
        var appName = targetPackage
        var appIcon = getDrawable(android.R.drawable.sym_def_app_icon)
        try {
            val appInfo = pm.getApplicationInfo(targetPackage, 0)
            appName = pm.getApplicationLabel(appInfo).toString()
            appIcon = pm.getApplicationIcon(appInfo)
        } catch (_: Exception) {}

        // Root container
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B0B0D"))
            setPadding(64, 96, 64, 96)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        // Brand badge: "EZZE BREAK"
        val brandBadge = TextView(this).apply {
            text = "EZZE BREAK"
            setTextColor(Color.parseColor("#F04452"))
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            letterSpacing = 0.2f
        }
        rootLayout.addView(brandBadge)

        // Spacer
        rootLayout.addView(createSpacer(48))

        // App Icon
        val iconView = ImageView(this).apply {
            setImageDrawable(appIcon)
            layoutParams = LinearLayout.LayoutParams(180, 180).apply {
                gravity = Gravity.CENTER
            }
        }
        rootLayout.addView(iconView)

        // Spacer
        rootLayout.addView(createSpacer(24))

        // App Name
        val appNameView = TextView(this).apply {
            text = appName
            setTextColor(Color.WHITE)
            textSize = 22f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        rootLayout.addView(appNameView)

        // Spacer
        rootLayout.addView(createSpacer(32))

        // Restriction Title & Body
        val isDailyLimitOver = reason == "limit_over"

        val titleView = TextView(this).apply {
            text = if (isDailyLimitOver) {
                "App usage time limit over."
            } else {
                "Continuous session limit reached."
            }
            setTextColor(Color.parseColor("#F04452"))
            textSize = 19f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        rootLayout.addView(titleView)

        rootLayout.addView(createSpacer(12))

        val subtitleView = TextView(this).apply {
            text = if (isDailyLimitOver) {
                "Please use it tomorrow, or use an intentional override with your daily PIN."
            } else {
                "Time for a mindful break! Complete your physical exercises to refresh and refocus."
            }
            setTextColor(Color.parseColor("#B5B5BC"))
            textSize = 15f
            gravity = Gravity.CENTER
            setLineSpacing(6f, 1.2f)
        }
        rootLayout.addView(subtitleView)

        // Spacer
        rootLayout.addView(createSpacer(56))

        // Primary Action Button
        val primaryBtn = Button(this).apply {
            text = if (isDailyLimitOver) {
                "Use Anyway (Override with PIN)"
            } else {
                "Start Break & Exercises"
            }
            setTextColor(Color.WHITE)
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#D92D3E"))
                cornerRadius = 32f
            }
            setPadding(32, 28, 32, 28)
            setOnClickListener {
                openEzzeBreak(targetPackage, if (isDailyLimitOver) "START_OVERRIDE" else "START_BREAK")
            }
        }
        val btnParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, 0, 0, 24)
        }
        rootLayout.addView(primaryBtn, btnParams)

        // Secondary Action: Return to Home
        val homeBtn = Button(this).apply {
            text = "Return to Home"
            setTextColor(Color.parseColor("#B5B5BC"))
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#151518"))
                setStroke(2, Color.parseColor("#303036"))
                cornerRadius = 32f
            }
            setPadding(32, 28, 32, 28)
            setOnClickListener {
                goToHomeScreen()
            }
        }
        rootLayout.addView(homeBtn, btnParams)

        setContentView(rootLayout)
    }

    private fun createSpacer(heightPx: Int): LinearLayout {
        return LinearLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                heightPx
            )
        }
    }

    private fun openEzzeBreak(packageName: String, action: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", action)
            putExtra("package_name", packageName)
        }
        startActivity(intent)
        finish()
    }

    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Prevent going back directly into restricted app; go to home instead
        goToHomeScreen()
    }
}
