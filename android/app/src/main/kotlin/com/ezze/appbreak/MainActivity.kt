package com.ezze.appbreak

import android.Manifest
import android.app.AppOpsManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Process
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.ezze.break/channel"
    private var methodChannel: MethodChannel? = null
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    private var pendingAction: String? = null
    private var pendingPackageName: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        EzzeRestrictionManager.init(applicationContext)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.getStringExtra("action")
        val pkg = intent?.getStringExtra("package_name")
        if (action != null) {
            pendingAction = action
            pendingPackageName = pkg
            methodChannel?.invokeMethod("onPendingAction", mapOf(
                "action" to action,
                "packageName" to (pkg ?: "")
            ))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Set foreground change listener from accessibility service
        EzzeAccessibilityService.foregroundListener = { pkgName ->
            runOnUiThread {
                methodChannel?.invokeMethod("onForegroundAppChanged", mapOf("packageName" to pkgName))
            }
        }

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    backgroundExecutor.execute {
                        try {
                            val apps = queryInstalledApps()
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("QUERY_ERROR", e.message, null) }
                        }
                    }
                }
                "checkUsagePermission" -> {
                    result.success(isUsageAccessGranted())
                }
                "openUsageSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "openOverlaySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "checkNotificationPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "updateRestrictions" -> {
                    val rawMap = call.argument<Map<String, String>>("restrictions") ?: emptyMap()
                    EzzeRestrictionManager.updateAllRestrictions(this, rawMap)
                    result.success(true)
                }
                "triggerRestriction" -> {
                    val targetPackage = call.argument<String>("packageName") ?: ""
                    val reason = call.argument<String>("reason") ?: "break"
                    val intent = Intent(this, RestrictionActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra(RestrictionActivity.EXTRA_PACKAGE_NAME, targetPackage)
                        putExtra(RestrictionActivity.EXTRA_REASON, reason)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "getUsageStats" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val stats = queryUsageStats(startTime, endTime)
                    result.success(stats)
                }
                "savePdfToDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: "EzzeBreak_Report.pdf"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("INVALID_ARGS", "PDF bytes cannot be null", null)
                        return@setMethodCallHandler
                    }
                    backgroundExecutor.execute {
                        try {
                            val savedPath = savePdfFile(fileName, bytes)
                            runOnUiThread { result.success(savedPath) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("SAVE_FAILED", e.message, null) }
                        }
                    }
                }
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "File path cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    val success = openPdfFile(filePath)
                    result.success(success)
                }
                "getPendingAction" -> {
                    val action = pendingAction
                    val pkg = pendingPackageName
                    pendingAction = null
                    pendingPackageName = null
                    if (action != null) {
                        result.success(mapOf("action" to action, "packageName" to (pkg ?: "")))
                    } else {
                        result.success(null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isUsageAccessGranted(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (EzzeAccessibilityService.isServiceRunning) return true
        val serviceId = "$packageName/${EzzeAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(serviceId) || enabledServices.contains(packageName)
    }

    private fun queryInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(intent, 0)
        val list = mutableListOf<Map<String, Any>>()
        val seen = mutableSetOf<String>()

        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            if (pkg == packageName || seen.contains(pkg)) continue
            seen.add(pkg)

            val name = info.loadLabel(pm).toString()
            val isSystem = (info.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            var iconBase64 = ""
            try {
                val iconDrawable = info.loadIcon(pm)
                val bitmap = drawableToBitmap(iconDrawable)
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
                val bytes = stream.toByteArray()
                iconBase64 = android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
            } catch (_: Exception) {}

            list.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to name,
                    "isSystemApp" to isSystem,
                    "iconBase64" to iconBase64
                )
            )
        }
        // Sort alphabetically by app name
        list.sortBy { (it["appName"] as? String)?.lowercase() ?: "" }
        return list
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width.coerceAtMost(144), height.coerceAtMost(144), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun queryUsageStats(startTime: Long, endTime: Long): Map<String, Long> {
        val result = mutableMapOf<String, Long>()
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? android.app.usage.UsageStatsManager ?: return result
            val stats = usm.queryUsageStats(
                android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            for (stat in stats) {
                if (stat.totalTimeInForeground > 0) {
                    val current = result[stat.packageName] ?: 0L
                    result[stat.packageName] = current + stat.totalTimeInForeground
                }
            }
        } catch (_: Exception) {}
        return result
    }

    private fun savePdfFile(fileName: String, bytes: ByteArray): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Could not create MediaStore entry")
            resolver.openOutputStream(uri)?.use { os ->
                os.write(bytes)
                os.flush()
            }
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            File(downloadsDir, fileName).absolutePath
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { os ->
                os.write(bytes)
                os.flush()
            }
            file.absolutePath
        }
    }

    private fun openPdfFile(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            } else {
                Uri.fromFile(file)
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val chooser = Intent.createChooser(intent, "Open Ezze Break Report")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            true
        } catch (_: Exception) {
            false
        }
    }
}
