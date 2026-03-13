//
//  WorkspaceManager.swift
//  Jarvis
//

import Foundation
import UIKit

final class WorkspaceManager: @unchecked Sendable {
    static let shared = WorkspaceManager()

    private init() {}

    var workspaceDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("JarvisWorkspace", isDirectory: true)
    }

    func ensureWorkspaceDirectory() throws -> URL {
        let url = workspaceDirectory
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func listFiles() -> [URL] {
        guard let dir = try? ensureWorkspaceDirectory() else { return [] }
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])) ?? []
        return urls.sorted { a, b in
            let da = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return da > db
        }
    }

    func save(image: UIImage) throws -> URL {
        let dir = try ensureWorkspaceDirectory()
        let name = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = dir.appending(path: "photo-\(name).jpg")
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: [.atomic])
        return url
    }
}

