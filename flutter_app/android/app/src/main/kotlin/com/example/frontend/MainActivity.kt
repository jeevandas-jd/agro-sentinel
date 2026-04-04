package com.example.frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.frontend/secrets",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGeminiApiKey" -> result.success(BuildConfig.GEMINI_API_KEY)
                "getGroqApiKey" -> result.success(BuildConfig.GROQ_API_KEY)
                else -> result.notImplemented()
            }
        }
    }
}
