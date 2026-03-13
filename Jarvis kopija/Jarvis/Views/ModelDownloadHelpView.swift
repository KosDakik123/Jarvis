//
//  ModelDownloadHelpView.swift
//  Jarvis
//

import SwiftUI

struct ModelDownloadHelpView: View {
    @Environment(\.dismiss) private var dismiss

    private var modelsPath: String {
        ModelManager.modelsDirectory.path
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to add models")
                        .font(.title3.weight(.semibold))

                    Group {
                        Text("1. Download a GGUF model")
                            .font(.headline)
                        Text("Use a browser on your Mac to download a *.gguf* file, for example:")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Llama 3.2 3B Instruct Q4_K_M")
                            Text("• Phi-3 Mini Instruct")
                            Text("• Gemma / Mistral GGUF variants")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.jarvisSecondary)
                    }

                    Group {
                        Text("2. Copy it into JARVIS")
                            .font(.headline)
                        Text("On a real iPhone / iPad:")
                        Text("• Open the Files app → On My iPhone → JARVIS → Models\n• If the Models folder doesn’t exist, it will be created the first time you open JARVIS.\n• Drop the .gguf file into that Models folder.")
                            .font(.subheadline)
                            .foregroundStyle(Color.jarvisSecondary)

                        Text("On a simulator:")
                        Text("• Use Finder → Go to Folder… and paste the path below to open the app’s Documents folder.")
                            .font(.subheadline)
                            .foregroundStyle(Color.jarvisSecondary)

                        Text(modelsPath)
                            .font(.footnote.monospaced())
                            .padding(8)
                            .background(Color.jarvisSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Group {
                        Text("3. Select the model")
                            .font(.headline)
                        Text("Return to JARVIS → Settings → Model and pick your .gguf file from the list.\nYou can keep multiple models and switch between them at any time.")
                            .font(.subheadline)
                            .foregroundStyle(Color.jarvisSecondary)
                    }

                    Button {
                        openModelsFolderInFiles()
                    } label: {
                        Label("Open Models folder in Files", systemImage: "folder.badge.gearshape")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.jarvisAccent)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.jarvisBackground.ignoresSafeArea())
            .navigationTitle("Add Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func openModelsFolderInFiles() {
        let url = ModelManager.modelsDirectory
        _ = try? ModelManager.ensureModelsDirectory()
        UIApplication.shared.open(url)
    }
}

