//
//  ChannelLogo.swift
//  myTV
//
//  Created by Anurag Chourasia on 25/01/26.
//

import SwiftUI
import DesignTokensKit

struct ChannelLogo: View {
    let url: URL?
    @State private var previewPresented = false
    var height: CGFloat = DesignMetric.p40
    var width: CGFloat = DesignMetric.p40

    var body: some View {
        CachedAsyncImage(url: url) {
            ZStack {
                DesignColor.grouped

                Image(systemName: "tv")
                    .foregroundColor(DesignColor.secondary)
            }
        }
        .scaledToFit()
        .frame(width: width, height: height)
        .background(DesignColor.grouped)
        .cornerRadius(CornerRadius.six)
        .contentShape(Rectangle())
        .highPriorityGesture(LongPressGesture().onEnded { _ in
            if AppRuntime.logoPreviewEnabled { previewPresented = true }
        })
        .accessibilityLabel("Channel logo")
        .accessibilityActions {
            if AppRuntime.logoPreviewEnabled {
                Button("Preview logo") { previewPresented = true }
            }
        }
        .sheet(isPresented: $previewPresented) { ChannelLogoPreview(url: url) }
    }
}

private struct ChannelLogoPreview: View {
    @StateObject private var loader: ImageLoader
    @State private var sharing = false
    @State private var shareError: String?
    @Environment(\.dismiss) private var dismiss

    init(url: URL?) { _loader = StateObject(wrappedValue: ImageLoader(url: url)) }

    private var image: UIImage? {
        if case .success(let image) = loader.state { return image }
        return nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                        .accessibilityLabel("Channel logo")
                } else if case .failure = loader.state {
                    Label("Logo unavailable", systemImage: "tv")
                } else { ProgressView("Loading logo…") }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Spacing.sixteen)
            .background(DesignColor.grouped)
            .navigationTitle("Logo preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close logo preview")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { sharing = true } label: { Label("Share logo", systemImage: "square.and.arrow.up") }
                        .disabled(image == nil)
                }
            }
            .tint(DesignColor.primary)
            .sheet(isPresented: $sharing) {
                if let image { LogoShareSheet(image: image) { shareError = $0.localizedDescription } }
            }
            .alert("Couldn’t share logo", isPresented: Binding(
                get: { shareError != nil }, set: { if !$0 { shareError = nil } }
            )) { Button("OK", role: .cancel) {} } message: { Text(shareError ?? "") }
            .task { await loader.load() }
        }
    }
}

private struct LogoShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let onError: (Error) -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, error in
            if let error { onError(error) }
        }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
