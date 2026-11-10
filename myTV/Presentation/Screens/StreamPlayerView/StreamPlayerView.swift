//
//  StreamPlayerView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI
import AVKit
import FoundationKit

struct StreamPlayerView: UIViewControllerRepresentable {

    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsVideoFrameAnalysis = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.modalPresentationStyle = .fullScreen
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.showsPlaybackControls = true
        PlaybackAudioSession.activate()
        
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {}

    func play() {
        player.play()
    }
}

/// Audio-session configuration can block too, so keep it off the UI executor.
private enum PlaybackAudioSession {
    private nonisolated static let queue = DispatchQueue(label: "myTV.playback-audio-session")
    private nonisolated static let logger: any AppLogger = UnifiedLogger(subsystem: "com.mytv.player", category: "audio")

    nonisolated static func activate() {
        queue.async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .moviePlayback)
                if #available(iOS 27.0, *) {
                    session.activate(options: []) { activated, error in
                        if let error {
                            logger.log("Failed to activate AVAudioSession: \(error.localizedDescription)", level: .error)
                        } else if !activated {
                            logger.log("AVAudioSession activation did not complete.", level: .warning)
                        }
                    }
                } else {
                    // Older iOS has only the synchronous API. This serial queue is not the main queue.
                    try session.setActive(true)
                }
            } catch {
                logger.log("Failed to set up AVAudioSession: \(error.localizedDescription)", level: .error)
            }
        }
    }
}
