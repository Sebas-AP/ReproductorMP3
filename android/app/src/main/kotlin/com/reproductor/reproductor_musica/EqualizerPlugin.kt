package com.reproductor.reproductor_musica

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class EqualizerPlugin : FlutterPlugin, MethodCallHandler, StreamHandler {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventSink? = null

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var audioSessionId: Int = 0
    private var preampValue: Double = 0.0

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "com.reproductor.equalizer")
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.reproductor.equalizer/state")
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        release()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        executor.execute {
            try {
                when (call.method) {
                    "init" -> {
                        val sessionId = call.argument<Int>("audioSessionId") ?: 0
                        initEqualizer(sessionId)
                        mainHandler.post { result.success(null) }
                    }
                    "setGain" -> {
                        val band = call.argument<Int>("band") ?: 0
                        val gain = call.argument<Double>("gain") ?: 0.0
                        setBandGain(band, gain)
                        mainHandler.post { result.success(null) }
                    }
                    "setPreamp" -> {
                        val gain = call.argument<Double>("gain") ?: 0.0
                        setPreamp(gain)
                        mainHandler.post { result.success(null) }
                    }
                    "setBassBoost" -> {
                        val gain = call.argument<Double>("gain") ?: 0.0
                        setBassBoost(gain)
                        mainHandler.post { result.success(null) }
                    }
                    "setVirtualizer" -> {
                        val gain = call.argument<Double>("gain") ?: 0.0
                        setVirtualizer(gain)
                        mainHandler.post { result.success(null) }
                    }
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        setEnabled(enabled)
                        mainHandler.post { result.success(null) }
                    }
                    "release" -> {
                        release()
                        mainHandler.post { result.success(null) }
                    }
                    else -> mainHandler.post { result.notImplemented() }
                }
            } catch (e: Exception) {
                Log.e("EqualizerPlugin", "Error: ${e.message}")
                mainHandler.post { result.error("ERROR", e.message, null) }
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventSink) {
        eventSink = events
        sendStateUpdate()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun initEqualizer(sessionId: Int) {
        audioSessionId = sessionId
        try {
            equalizer = Equalizer(0, audioSessionId)
            equalizer?.enabled = true

            bassBoost = BassBoost(0, audioSessionId)
            bassBoost?.enabled = true

            virtualizer = Virtualizer(0, audioSessionId)
            virtualizer?.enabled = true

            sendStateUpdate()
        } catch (e: Exception) {
            Log.e("EqualizerPlugin", "Init error: ${e.message}")
        }
    }

    private fun setBandGain(band: Int, gain: Double) {
        equalizer?.let {
            val count = it.numberOfBands.toInt()
            if (band in 0 until count) {
                val minGain = it.bandLevelRange[0]
                val maxGain = it.bandLevelRange[1]
                val clampedGain = gain.coerceIn(minGain.toDouble() / 100.0, maxGain.toDouble() / 100.0)
                val hundredthsOfDb = (clampedGain * 100).toInt()
                it.setBandLevel(band.toShort(), hundredthsOfDb.toShort())
                sendStateUpdate()
            }
        }
    }

    private fun setPreamp(gain: Double) {
        preampValue = gain
        sendStateUpdate()
    }

    private fun setBassBoost(gain: Double) {
        bassBoost?.let {
            val strength = (gain / 10.0 * 1000).toInt().coerceIn(0, 1000)
            it.setStrength(strength.toShort())
            sendStateUpdate()
        }
    }

    private fun setVirtualizer(gain: Double) {
        virtualizer?.let {
            val strength = (gain / 10.0 * 1000).toInt().coerceIn(0, 1000)
            it.setStrength(strength.toShort())
            sendStateUpdate()
        }
    }

    private fun setEnabled(enabled: Boolean) {
        equalizer?.enabled = enabled
        bassBoost?.enabled = enabled
        virtualizer?.enabled = enabled
        sendStateUpdate()
    }

    private fun release() {
        equalizer?.release()
        equalizer = null
        bassBoost?.release()
        bassBoost = null
        virtualizer?.release()
        virtualizer = null
        sendStateUpdate()
    }

    private fun sendStateUpdate() {
        val sink = eventSink ?: return
        executor.execute {
            val gains = mutableListOf<Double>()
            equalizer?.let { eq ->
                val bandCount = eq.numberOfBands.toInt()
                for (i in 0 until bandCount) {
                    gains.add(eq.getBandLevel(i.toShort()).toDouble() / 100.0)
                }
            }
            val preamp = preampValue
            val bass = bassBoost?.let { it.roundedStrength.toDouble() / 1000.0 * 10.0 } ?: 0.0
            val virtual = virtualizer?.let { it.roundedStrength.toDouble() / 1000.0 * 10.0 } ?: 0.0
            val enabled = equalizer?.enabled ?: false

            val map = mapOf(
                "gains" to gains,
                "preamp" to preamp,
                "bassBoost" to bass,
                "virtualizer" to virtual,
                "enabled" to enabled
            )
            mainHandler.post {
                sink.success(map)
            }
        }
    }
}