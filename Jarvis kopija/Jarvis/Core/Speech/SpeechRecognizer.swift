//
//  SpeechRecognizer.swift
//  Jarvis
//

import AVFoundation
import Speech

enum SpeechRecognizerError: Error {
    case recognizerUnavailable
    case invalidAudioFormat
}

/// Streaming speech-to-text using SFSpeechRecognizer and AVAudioEngine.
final class SpeechRecognizer: NSObject, @unchecked Sendable {

    private let recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let engine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var latestTranscript: String = ""
    private var silenceTimer: DispatchSourceTimer?
    private let silenceTimeout: TimeInterval = 1.5

    var onPartialResult: (@Sendable (String) -> Void)?
    var onFinalResult: (@Sendable (String) -> Void)?
    var onError: (@Sendable (Error) -> Void)?

    override init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func start() throws {
        // Defensive: stop any previous run.
        stop()
        try AudioSessionManager.shared.configureForVoice()

        guard let recognizer, recognizer.isAvailable else {
            throw SpeechRecognizerError.recognizerUnavailable
        }

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SpeechRecognizerError.invalidAudioFormat
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            // Prefer on-device when available; Speech will fail if not supported for locale/device.
            request.requiresOnDeviceRecognition = false
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, err in
            if let err = err {
                let ns = err as NSError
                // kAFAssistantErrorDomain: treat as non-fatal; surface transcript if we have it.
                let isAssistantDomain = ns.domain == "kAFAssistantErrorDomain"
                // AVFAudio 1852797029 (kAudioCodecIllegalOperationError): session/engine state;
                // don't surface so user can try again after we've released the session in stop().
                let isRecoverableAVError = ns.code == 1852797029
                if isAssistantDomain || isRecoverableAVError {
                    if let self {
                        let text = self.latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            self.stop()
                            self.onFinalResult?(text)
                        } else {
                            self.stop()
                        }
                    }
                    return
                }
                self?.onError?(err)
                return
            }
            guard let result = result else { return }
            self?.latestTranscript = result.bestTranscription.formattedString
            self?.resetSilenceTimer()
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                self?.stop()
                self?.onFinalResult?(text)
            } else {
                self?.onPartialResult?(result.bestTranscription.formattedString)
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        engine.prepare()
        try engine.start()
    }

    func stop() {
        silenceTimer?.cancel()
        silenceTimer = nil
        request?.endAudio()
        recognitionTask?.cancel()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        request = nil
        recognitionTask = nil
        latestTranscript = ""
        // Release the audio session so the next start() gets a clean activate and avoids 1852797029.
        try? AudioSessionManager.shared.setActive(false)
    }

    private func resetSilenceTimer() {
        silenceTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        timer.schedule(deadline: .now() + silenceTimeout)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let text = self.latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            self.stop()
            self.onFinalResult?(text)
        }
        silenceTimer = timer
        timer.resume()
    }
}
