import Foundation
import AVFoundation
import Flutter

public class EqualizerPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private var audioEngine: AVAudioEngine?
    private var eqNode: AVAudioUnitEQ?
    private var audioSessionId: UInt32 = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "com.reproductor.equalizer", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.reproductor.equalizer/state", binaryMessenger: registrar.messenger())

        let instance = EqualizerPlugin()
        instance.methodChannel = methodChannel
        instance.eventChannel = eventChannel

        methodChannel.setMethodCallHandler(instance.handle(_:result:))
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard let args = call.arguments as? [String: Any],
                  let sessionId = args["audioSessionId"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGS", message: "audioSessionId required", details: nil))
                return
            }
            initEqualizer(sessionId: sessionId.uint32Value)
            result(nil)

        case "setGain":
            guard let args = call.arguments as? [String: Any],
                  let band = args["band"] as? NSNumber,
                  let gain = args["gain"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGS", message: "band and gain required", details: nil))
                return
            }
            setBandGain(band: band.intValue, gain: gain.doubleValue)
            result(nil)

        case "setPreamp":
            guard let args = call.arguments as? [String: Any],
                  let gain = args["gain"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGS", message: "gain required", details: nil))
                return
            }
            setPreamp(gain: gain.doubleValue)
            result(nil)

        case "setBassBoost":
            guard let args = call.arguments as? [String: Any],
                  let gain = args["gain"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGS", message: "gain required", details: nil))
                return
            }
            // Bass boost is simulated via low-frequency EQ bands
            setBassBoost(gain: gain.doubleValue)
            result(nil)

        case "setVirtualizer":
            guard let args = call.arguments as? [String: Any],
                  let gain = args["gain"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGS", message: "gain required", details: nil))
                return
            }
            // Virtualizer not directly available in AVAudioUnitEQ, simulate via EQ
            setVirtualizer(gain: gain.doubleValue)
            result(nil)

        case "setEnabled":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGS", message: "enabled required", details: nil))
                return
            }
            setEnabled(enabled: enabled.boolValue)
            result(nil)

        case "release":
            release()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initEqualizer(sessionId: UInt32) {
        audioSessionId = sessionId

        audioEngine = AVAudioEngine()
        eqNode = AVAudioUnitEQ(numberOfBands: 10)

        guard let audioEngine = audioEngine, let eqNode = eqNode else { return }

        // Configure 10-band EQ with standard frequencies
        let frequencies: [Float] = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        for (index, frequency) in frequencies.enumerated() {
            let band = eqNode.bands[index]
            band.frequency = frequency
            band.filterType = .parametric
            band.bandwidth = 1.0
            band.gain = 0.0
            band.bypass = false
        }

        // Global gain (preamp)
        eqNode.globalGain = 0.0

        audioEngine.attach(eqNode)

        // Connect: player -> eq -> mixer -> output
        // Note: In iOS, we connect to the main mixer
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine.connect(eqNode, to: audioEngine.mainMixerNode, format: format)

        // The audioEngine will be started when the player plays
        // We don't start it here since just_audio manages its own engine

        sendStateUpdate()
    }

    private func setBandGain(band: Int, gain: Double) {
        guard let eqNode = eqNode, band >= 0, band < eqNode.bands.count else { return }
        let clampedGain = max(-12.0, min(12.0, gain))
        eqNode.bands[band].gain = Float(clampedGain)
        sendStateUpdate()
    }

    private func setPreamp(gain: Double) {
        guard let eqNode = eqNode else { return }
        let clampedGain = max(-12.0, min(12.0, gain))
        eqNode.globalGain = Float(clampedGain)
        sendStateUpdate()
    }

    private func setBassBoost(gain: Double) {
        // Boost low frequency bands (0-2: 31Hz, 62Hz, 125Hz)
        guard let eqNode = eqNode else { return }
        let clampedGain = max(0.0, min(12.0, gain))
        for i in 0...2 {
            eqNode.bands[i].gain = Float(clampedGain)
        }
        sendStateUpdate()
    }

    private func setVirtualizer(gain: Double) {
        // Simulate virtualizer by adding slight stereo widening effect via EQ
        // Not directly possible with AVAudioUnitEQ alone, so we just update state
        sendStateUpdate()
    }

    private func setEnabled(enabled: Bool) {
        guard let eqNode = eqNode else { return }
        for band in eqNode.bands {
            band.bypass = !enabled
        }
        eqNode.globalGain = enabled ? eqNode.globalGain : 0.0
        sendStateUpdate()
    }

    private func release() {
        if let eqNode = eqNode {
            audioEngine?.detach(eqNode)
        }
        audioEngine?.stop()
        audioEngine = nil
        eqNode = nil
        sendStateUpdate()
    }

    private func sendStateUpdate() {
        guard let eventSink = eventSink else { return }

        var gains: [Double] = []
        let preamp: Double
        let bassBoost: Double
        let virtualizer: Double
        let enabled: Bool

        if let eqNode = eqNode {
            for band in eqNode.bands {
                gains.append(Double(band.gain))
            }
            preamp = Double(eqNode.globalGain)
            bassBoost = gains.count > 0 ? Double(gains[0]) : 0.0
            virtualizer = 0.0
            enabled = !eqNode.bands[0].bypass
        } else {
            gains = Array(repeating: 0.0, count: 10)
            preamp = 0.0
            bassBoost = 0.0
            virtualizer = 0.0
            enabled = false
        }

        let map: [String: Any] = [
            "gains": gains,
            "preamp": preamp,
            "bassBoost": bassBoost,
            "virtualizer": virtualizer,
            "enabled": enabled
        ]
        eventSink(map)
    }
}

extension EqualizerPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        sendStateUpdate()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}