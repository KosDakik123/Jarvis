//
//  HistoryView.swift
//  Jarvis
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Bindable var controller: AssistantController
    @Binding var selectedTab: Int
    @Query(sort: \ConversationEntity.updatedAt, order: .reverse)
    private var conversations: [ConversationEntity]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Conversations")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            controller.clearConversation()
                            // Start a brand new persisted conversation implicitly.
                            selectedTab = 0
                        } label: {
                            Label("New chat", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.jarvisAccent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    if conversations.isEmpty {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No conversations yet")
                                .font(.subheadline.weight(.semibold))
                            Text("Your chats with JARVIS will appear here once you start talking.")
                                .font(.footnote)
                                .foregroundStyle(Color.jarvisSecondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 20)
                        Spacer()
                    } else {
                        List {
                            ForEach(conversations) { convo in
                                NavigationLink {
                                    ConversationDetailView(conversation: convo)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(convo.title)
                                            .font(.headline)
                                        if let last = convo.messages.sorted(by: { $0.createdAt > $1.createdAt }).first {
                                            Text(last.content)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.jarvisSecondary)
                                                .lineLimit(1)
                                        }
                                        Text(convo.updatedAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(Color.jarvisSecondary)
                                    }
                                }
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        modelContext.delete(convo)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct ConversationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showShare = false

    let conversation: ConversationEntity

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(conversation.messages.sorted(by: { $0.createdAt < $1.createdAt })) { msg in
                    let role = Message.Role(rawValue: msg.role) ?? .assistant
                    let m = Message(role: role, content: msg.content, timestamp: msg.createdAt)
                    MessageBubble(message: m)
                }
            }
            .padding(.vertical, 12)
        }
        .background(AnimatedBackgroundView().ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    share(text: exportTranscript())
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func exportTranscript() -> String {
        conversation.messages
            .sorted(by: { $0.createdAt < $1.createdAt })
            .map { msg in
                let role = msg.role.lowercased()
                return "\(role.uppercased()): \(msg.content)"
            }
            .joined(separator: "\n\n")
    }

    private func share(text: String) {
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(vc, animated: true)
    }
}


