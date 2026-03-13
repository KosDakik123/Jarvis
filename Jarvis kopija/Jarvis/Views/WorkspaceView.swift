//
//  WorkspaceView.swift
//  Jarvis
//

import SwiftUI

struct WorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL] = []

    var body: some View {
        NavigationStack {
            List {
                if files.isEmpty {
                    Text("No files yet. Use the camera button on the main screen.")
                        .foregroundStyle(Color.jarvisSecondary)
                } else {
                    ForEach(files, id: \.self) { url in
                        HStack(spacing: 12) {
                            thumbnail(for: url)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .font(.callout)
                                Text(url.deletingLastPathComponent().lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(Color.jarvisSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                files = WorkspaceManager.shared.listFiles()
            }
        }
    }

    @ViewBuilder
    private func thumbnail(for url: URL) -> some View {
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.jarvisSurface
                Image(systemName: "doc.fill")
                    .foregroundStyle(Color.jarvisSecondary)
            }
        }
    }
}

