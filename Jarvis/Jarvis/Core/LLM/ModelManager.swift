//
//  ModelManager.swift
//  Jarvis
//

import Foundation

/// Model file management — bundled vs documents directory, listing GGUF files.
enum ModelManager {

    /// Directory in app Documents where downloaded/copied GGUF models live.
    static var modelsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Models", isDirectory: true)
    }

    /// Bundle resource path for a bundled model (e.g. default).
    static func bundledModelURL(name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "gguf", subdirectory: "Models")
    }

    /// Ensure Models directory exists; return URL.
    static func ensureModelsDirectory() throws -> URL {
        let url = modelsDirectory
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// List all .gguf files in Documents/Models (and optionally bundle).
    static func listAvailableModels(includeBundle: Bool = true) -> [URL] {
        var urls: [URL] = []
        if let dir = try? ensureModelsDirectory() {
            let contents = (try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil
            )) ?? []
            urls = contents.filter { $0.pathExtension == "gguf" }
        }
        if includeBundle,
           let root = Bundle.main.resourceURL {
            // Look for any .gguf in the entire app bundle, not only /Models,
            // so models added anywhere in the Xcode navigator still show up.
            let fm = FileManager.default
            if let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for case let url as URL in enumerator {
                    if url.pathExtension == "gguf" {
                        urls.append(url)
                    }
                }
            }
        }
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Display name for a model URL (filename without extension).
    static func displayName(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
