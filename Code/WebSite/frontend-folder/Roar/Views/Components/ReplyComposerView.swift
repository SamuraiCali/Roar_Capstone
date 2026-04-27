//
//  ReplyComposerView.swift
//  Roar
//
//  Created by Bourbon on 4/13/26.
//

import SwiftUI

struct ReplyComposerView: View {
    @Binding var replyingTo: Comment?
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    let onSend: () async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Header
            HStack {
                Text("Replying to \(replyingTo?.username ?? "user")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Cancel") {
                    replyingTo = nil
                    text = ""
                    isFocused = false
                }
                .font(.caption)
            }
            
            // Input row
            HStack {
                TextField(
                    "Replying to \(replyingTo?.username ?? "user")",
                    text: $text
                )
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                
                Button(action: {
                    Task {
                        await onSend()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5) // 👈 half screen
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .onAppear {
            isFocused = true
        }
    }
}
