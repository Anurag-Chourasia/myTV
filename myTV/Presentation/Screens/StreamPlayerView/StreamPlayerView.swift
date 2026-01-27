//
//  StreamPlayerView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//


import SwiftUI
import AVKit

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
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
        
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
