//
//  ImageAnalyzer.swift
//  Jarvis
//

import Foundation
import UIKit
import Vision

enum ImageAnalyzer {
    struct Result: Sendable {
        var ocrText: String
    }

    @MainActor
    static func analyze(image: UIImage) async -> Result {
        guard let cgImage = image.cgImage else { return Result(ocrText: "") }

        return await withCheckedContinuation { cont in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                let strings = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                // Keep it short: merge and truncate.
                let joined = strings.joined(separator: " • ")
                let ocr = joined.count > 400 ? String(joined.prefix(400)) + "…" : joined
                cont.resume(returning: Result(ocrText: ocr))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    cont.resume(returning: Result(ocrText: ""))
                }
            }
        }
    }
}

