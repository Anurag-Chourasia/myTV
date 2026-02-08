//
//  TypingEffectViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//

import Combine
import SwiftUI

@MainActor
final class TypingEffectViewModel: ObservableObject {
    let previewWordLimit: Int
    let typingInterval: TimeInterval
    private var fullText: String = "" // Keep reference to original text

    @Published private(set) var displayedText: String = ""
    @Published private(set) var isExpanded = false

    private var words: [String] = []
    private var currentWordIndex = 0
    private var typingTask: Task<Void, Never>?

    init(previewWordLimit: Int = 13, typingInterval: TimeInterval = 0.15) {
        self.previewWordLimit = previewWordLimit
        self.typingInterval = typingInterval
        setText(Localizable.About.Developer.summary)
    }

    func setText(_ text: String) {
        stopTyping()
        self.fullText = text
        words = text.split(separator: " ").map(String.init)
        collapse()
    }

    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        startTyping()
    }
    
    func collapse() {
        stopTyping()
        isExpanded = false
        currentWordIndex = min(previewWordLimit, words.count)
        let preview = words.prefix(currentWordIndex).joined(separator: " ")
        displayedText = words.count > previewWordLimit ? "\(preview)..." : preview
    }

    var toggleButtonTitle: String {
        isExpanded ? Localizable.App.showLess : Localizable.App.readMore
    }

    private func startTyping() {
        stopTyping()
        displayedText = words.prefix(currentWordIndex).joined(separator: " ")
        typingTask = Task { [words, typingInterval] in
            while !Task.isCancelled, currentWordIndex < words.count {
                try? await Task.sleep(nanoseconds: UInt64(typingInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                currentWordIndex += 1
                withAnimation(.linear(duration: 0.1)) {
                    displayedText = words.prefix(currentWordIndex).joined(separator: " ")
                }
            }
        }
    }

    private func stopTyping() {
        typingTask?.cancel()
        typingTask = nil
    }
}
