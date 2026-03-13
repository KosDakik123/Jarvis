//
//  PermissionsManager.swift
//  Jarvis
//

import AVFoundation
import Speech

enum PermissionsManager {

    static func requestMicrophone() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    static func requestSpeechRecognition() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    static func requestAll() async -> (mic: Bool, speech: Bool) {
        async let mic = requestMicrophone()
        async let speech = requestSpeechRecognition()
        return (await mic, await speech)
    }
}
