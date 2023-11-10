//
//  ClipListTableViewCell.swift
//  NewFannerCam
//
//  Created by Prawin Bhagat on 25/10/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

class ClipListTableViewCell: UITableViewCell {
    var playerLayer: AVPlayerLayer?
    @IBOutlet weak var clipView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setVideo(url: URL) {
           let player = AVPlayer(url: url)
           playerLayer = AVPlayerLayer(player: player)
           playerLayer?.frame = clipView.bounds
        clipView.layer.addSublayer(playerLayer!)
           player.play()
       }
}
