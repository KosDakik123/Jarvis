//
//  ChatView.swift
//  Jarvis
//

import SwiftUI

struct ChatView: View {
    @Bindable var controller: AssistantController
    var showText: Bool = true

    var body: some View {
        if showText {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(controller.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .jarvisMessageTransition()
                        }
                        if controller.state == .listening,
                           !controller.partialTranscript.isEmpty {
                            voiceDraftBubble
                                .id("voice-draft")
                        }
                        if !controller.streamingContent.isEmpty {
                            streamingBubble
                                .id("streaming")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onChange(of: controller.streamingContent) { _, _ in
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
                .onChange(of: controller.messages.count) { _, _ in
                    if let last = controller.messages.last {
                        withAnimation(.spring(response: 0.35)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: controller.partialTranscript) { _, _ in
                    if controller.state == .listening {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("voice-draft", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private var streamingBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.jarvisAccent.opacity(0.8))
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text("JARVIS")
                    .font(.caption)
                    .foregroundStyle(Color.jarvisSecondary)
                StreamingTextView(text: controller.streamingContent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.jarvisSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Spacer(minLength: 48)
        }
        .padding(.horizontal)
    }

    private var voiceDraftBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 4) {
                Text("You (voice)")
                    .font(.caption)
                    .foregroundStyle(Color.jarvisSecondary)
                Text(controller.partialTranscript)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.jarvisAccent.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Image(systemName: "person.wave.2.fill")
                .font(.title2)
                .foregroundStyle(Color.jarvisSecondary)
        }
        .padding(.horizontal)
    }

}

struct ChatInputBar: View {
    @Bindable var controller: AssistantController
    var onSend: (String) -> Void = { _ in }

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showCamera = false
    @State private var showDocumentPicker = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showDocumentPicker = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.jarvisAccent)
            }

            Button {
                showCamera = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(Color.jarvisAccent)
            }

            TextField("Message JARVIS…", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { sendIfNeeded() }
                .disabled(controller.state == .listening)

            Toggle(isOn: Binding(
                get: { controller.state == .listening },
                set: { on in
                    if on { controller.startListening() } else { controller.stopListening() }
                }
            )) {
                Image(systemName: controller.state == .listening ? "mic.fill" : "mic")
                    .font(.title2)
                    .foregroundStyle(controller.state == .listening ? Color.red : Color.jarvisAccent)
            }
            .toggleStyle(.button)
            .labelsHidden()

            Button {
                sendIfNeeded()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(canSend ? Color.jarvisAccent : Color.jarvisSecondary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .onChange(of: controller.state) { _, newState in
            if newState == .thinking || newState == .speaking {
                isInputFocused = false
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                guard let image else { return }
                if let url = try? WorkspaceManager.shared.save(image: image) {
                    // For now, just drop a note into the chat so you see it in history.
                    let note = "📷 Captured photo: \(url.lastPathComponent)\n(Currently JARVIS can't see images yet, but the file is saved in your workspace.)"
                    Task { @MainActor in
                        await controller.sendText(note)
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { urls in
                guard !urls.isEmpty else { return }
                var note = "📎 Added files:\n"
                for url in urls {
                    note += "• \(url.lastPathComponent)\n"
                }
                note += "(Files are stored in your JARVIS workspace and stay on device.)"
                Task { @MainActor in
                    await controller.sendText(note)
                }
            }
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && controller.state != .thinking
    }

    private func sendIfNeeded() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isInputFocused = false
        inputText = ""
        onSend(text)
    }
}
