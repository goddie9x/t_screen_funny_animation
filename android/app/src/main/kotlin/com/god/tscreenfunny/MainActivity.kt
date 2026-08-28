package com.god.tscreenfunny

import flutter.overlay.window.flutter_overlay_window.OverlayService
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.god.tscreenfunny/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveToBack" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    "resetOverlayEngine" -> {
                        resetOverlayEngine()
                        result.success(null)
                    }
                    "moveOverlay" -> {
                        val x = (call.argument<Number>("x"))?.toInt() ?: 0
                        val y = (call.argument<Number>("y"))?.toInt() ?: 0
                        result.success(OverlayService.moveOverlay(x, y))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun resetOverlayEngine() {
        val cache = FlutterEngineCache.getInstance()
        val existing = cache.get("myCachedEngine")
        if (existing != null) {
            cache.remove("myCachedEngine")
            existing.destroy()
        }
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
        }
        val entry = DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "overlayMain")
        val engine = FlutterEngineGroup(applicationContext).createAndRunEngine(this, entry)
        cache.put("myCachedEngine", engine)
    }
}
