package com.starryflow.appsort

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.starryflow.appsort/apps"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
                    val apps = getInstalledApps(includeSystemApps)
                    result.success(apps)
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val iconBytes = getAppIconBytes(packageName)
                        if (iconBytes != null) {
                            result.success(iconBytes)
                        } else {
                            result.error("ICON_NOT_FOUND", "未找到应用图标: $packageName", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "缺少 packageName 参数", null)
                    }
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openApp(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "缺少 packageName 参数", null)
                    }
                }
                "openAppStore" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openAppStore(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "缺少 packageName 参数", null)
                    }
                }
                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openAppSettings(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "缺少 packageName 参数", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(includeSystemApps: Boolean): List<Map<String, Any?>> {
        val apps = mutableListOf<Map<String, Any?>>()
        val pm = packageManager

        // 使用 PackageManager.GET_ACTIVITIES 确保只获取可启动的应用
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolvedInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        }

        val processedPackages = mutableSetOf<String>()

        for (resolveInfo in resolvedInfos) {
            val packageName = resolveInfo.activityInfo.packageName
            if (processedPackages.contains(packageName)) continue
            processedPackages.add(packageName)

            try {
                val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(packageName, 0)
                }

                val applicationInfo = packageInfo.applicationInfo
                val isSystemApp = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0

                if (!includeSystemApps && isSystemApp) continue

                val appName = pm.getApplicationLabel(applicationInfo)?.toString() ?: packageName

                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "versionName" to (packageInfo.versionName ?: ""),
                    "versionCode" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) packageInfo.longVersionCode else packageInfo.versionCode.toLong()),
                    "isSystemApp" to isSystemApp,
                    "iconBytes" to getAppIconBytes(packageName)
                ))
            } catch (e: Exception) {
                // 跳过无法获取信息的应用
                continue
            }
        }

        // 按应用名排序
        return apps.sortedBy { it["appName"] as String }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable: Drawable?
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val icon = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(PackageManager.GET_ACTIVITIES)
                ).applicationInfo?.loadIcon(packageManager)
                drawable = icon
            } else {
                @Suppress("DEPRECATION")
                drawable = packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
                    .applicationInfo?.loadIcon(packageManager)
            }

            if (drawable == null) return null

            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                // 将 VectorDrawable 等转换为 Bitmap
                val width = drawable.intrinsicWidth.coerceAtLeast(1)
                val height = drawable.intrinsicHeight.coerceAtLeast(1)
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = android.graphics.Canvas(bmp)
                drawable.setBounds(0, 0, width, height)
                drawable.draw(canvas)
                bmp
            }

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun openApp(packageName: String) {
        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                startActivity(intent)
            }
        } catch (e: Exception) {
            // 静默处理
        }
    }

    private fun openAppStore(packageName: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("market://details?id=$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            // 没有应用市场，打开网页版
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun openAppSettings(packageName: String) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            // 静默处理
        }
    }
}
