package com.storycoe.storycoe_flutter

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.storycoe.tts/settings"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openTtsSettings" -> {
                    try {
                        // 尝试打开 TTS 设置页面
                        val intent = Intent("com.android.settings.TTS_SETTINGS")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // 备用方案：打开辅助功能设置
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", "无法打开设置页面: ${e2.message}", null)
                        }
                    }
                }
                "checkTtsEngine" -> {
                    // 检查是否有可用的 TTS 引擎
                    val intent = Intent(android.speech.tts.TextToSpeech.Engine.ACTION_CHECK_TTS_DATA)
                    val infos = packageManager.queryIntentActivities(intent, 0)
                    val engineList = infos.map { it.activityInfo.packageName }.toList()
                    result.success(engineList)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}