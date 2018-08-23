//
//  VideoViewController.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation
import AVFoundation
import UIKit

class VideoViewController: UIViewController {

    // MARK: - Properties
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    var videoURL: URL?
    var didSelectVideo: ((URL?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // With this line, we avoid that the player gets stopped during a facetime session of incoming call
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        guard let player = self.player else { assertionFailure("player was not set"); return }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    @IBAction func cancelTapped(_ sender: Any) {
        player?.pause()
        didSelectVideo?(nil)
    }
    
    @IBAction func selectTapped(_ sender: Any) {
        player?.pause()
        didSelectVideo?(videoURL)
    }
    
    private func setupView() {
        let queue = OperationQueue()
        queue.addOperation({
            guard let videoURL = self.videoURL else {
                assertionFailure("videoURL was not set")
                return
            }
            
            self.player = AVPlayer(url: videoURL)
            self.player?.actionAtItemEnd = .none
            
            let playerLayer = AVPlayerLayer(player: self.player)
            playerLayer.videoGravity = .resizeAspectFill
            self.playerLayer = playerLayer
            OperationQueue.main.addOperation({
                playerLayer.frame = self.view.bounds
                self.view.layer.insertSublayer(playerLayer, at: 0)
                self.player?.play()
            })
        })
    }
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        let playerItem = notification.object as? AVPlayerItem
        playerItem?.seek(to: kCMTimeZero)
    }

}
