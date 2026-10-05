package com.hypnoloop.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var fullscreenRequested = false
    private var awakeRequested = false
    private var foreground = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hypnoloop/project")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getVersion" -> {
                            @Suppress("DEPRECATION")
                            val info = packageManager.getPackageInfo(packageName, 0)
                            result.success(info.versionName)
                        }
                        "openProject" -> {
                            startActivity(Intent(Intent.ACTION_VIEW,
                                Uri.parse("https://github.com/Resker666/HypnoLoop")))
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (failure: Exception) {
                    result.error("project-failed", failure.message, null)
                }
            }
        val launcherIcons = LauncherIconManager(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hypnoloop/launcher-icon")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getCurrent" -> result.success(launcherIcons.current())
                        "setIcon" -> {
                            val id = call.argument<String>("id")
                            if (id == null) result.error("invalid-arguments", "Expected icon id", null)
                            else result.success(launcherIcons.select(id))
                        }
                        else -> result.notImplemented()
                    }
                } catch (failure: Exception) {
                    result.error("launcher-icon-failed", failure.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hypnoloop/display")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "apply" -> {
                        val fullscreen = call.argument<Any>("fullscreen")
                        val keepAwake = call.argument<Any>("keepAwake")
                        if (fullscreen !is Boolean || keepAwake !is Boolean) {
                            result.error("invalid-arguments", "Expected boolean display flags", null)
                        } else {
                            fullscreenRequested = fullscreen
                            awakeRequested = keepAwake
                            applyDisplay()
                            result.success(null)
                        }
                    }
                    "restore" -> {
                        fullscreenRequested = false
                        awakeRequested = false
                        applyDisplay()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun applyDisplay() {
        if (awakeRequested && foreground) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                if (fullscreenRequested) controller.hide(WindowInsets.Type.systemBars())
                else controller.show(WindowInsets.Type.systemBars())
            }
        } else {
            window.decorView.systemUiVisibility = if (fullscreenRequested) {
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            } else {
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) window.decorView.post { if (!isFinishing && !isDestroyed) applyDisplay() }
    }

    override fun onResume() {
        super.onResume()
        foreground = true
        applyDisplay()
    }

    override fun onPause() {
        foreground = false
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onPause()
    }

    override fun onDestroy() {
        awakeRequested = false
        fullscreenRequested = false
        applyDisplay()
        super.onDestroy()
    }
}
