//
//  AudioMessageTableViewCell.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 14/04/24.
//

import UIKit
import AVFoundation
import Kingfisher

class AudioMessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var waveformView: WaveformView!
    @IBOutlet weak var messageTime: UILabel!
    @IBOutlet weak var messageStatusLabel: UILabel!
    @IBOutlet weak var messageSeparatorDotView: UIView!
    @IBOutlet weak var receiverAvatarView: UIImageView!
    @IBOutlet weak var senderAvatarView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        waveformView.stop()
        waveformView.audioURL = nil
    }
    
    func setCellData(audioURL: URL, messageStatus: String?, senderAvatarURL: String?, isCurrentUser: Bool, messageReadStatus: Bool = true, view:UIViewController?) {
        configureCellUI(isCurrentUser: isCurrentUser, messageStatus: messageStatus, messageReadStatus: messageReadStatus, senderAvatarURL: senderAvatarURL)
        
        waveformView.audioURL = audioURL
        waveformView.view = view
    }
    
    private func configureUI() {
        receiverAvatarView.contentMode = .scaleAspectFill
        senderAvatarView.contentMode = .scaleAspectFill
        
        // Customize waveformView appearance
        waveformView.isHidden = false
        waveformView.backgroundColor = .clear
        waveformView.layer.cornerRadius = 8
        waveformView.layer.masksToBounds = true
        
        // Set up playback progress callback
        waveformView.playbackProgress = { [weak self] progress in
            self?.waveformView.progressBar.setProgress(progress, animated: true)
            self?.waveformView.setupDuration()
        }
    }
    
    private func configureCellUI(isCurrentUser: Bool, messageStatus: String?, messageReadStatus: Bool, senderAvatarURL: String?) {
        bubbleView.layer.cornerRadius = 20
        messageTime.text = messageStatus ?? ""
        
        if isCurrentUser {
            // Configure UI for current user's message
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#3780C2")
            messageTime.textColor = UIColorHex().hexStringToUIColor(hex: "#9BBFE0")
            messageSeparatorDotView.isHidden = false
            messageStatusLabel.isHidden = false
            messageStatusLabel.textColor = .white
            messageStatusLabel.text = messageReadStatus ? "Read" : "Sent"
            receiverAvatarView.isHidden = true
            senderAvatarView.isHidden = false
            
            if let avatarURL = URL(string: senderAvatarURL ?? "") {
                senderAvatarView.kf.setImage(with: avatarURL, placeholder: UIImage(systemName: "person.circle"))
            } else {
                senderAvatarView.image = UIImage(systemName: "person.circle")
            }
            senderAvatarView.layer.cornerRadius = senderAvatarView.bounds.height / 2
            waveformView.playButton.tintColor = .white
            waveformView.pauseButton.tintColor = .white
            waveformView.progressBar.trackTintColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
            waveformView.durationLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
        } else {
            // Configure UI for received message
            bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
            messageTime.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
            messageSeparatorDotView.isHidden = true
            messageStatusLabel.isHidden = true
            receiverAvatarView.isHidden = false
            senderAvatarView.isHidden = true
            
            if let avatarURL = URL(string: senderAvatarURL ?? "") {
                receiverAvatarView.kf.setImage(with: avatarURL, placeholder: UIImage(systemName: "person.circle"))
            } else {
                receiverAvatarView.image = UIImage(systemName: "person.circle")
            }
            receiverAvatarView.layer.cornerRadius = receiverAvatarView.bounds.height / 2
            waveformView.playButton.tintColor = .systemGray
            waveformView.pauseButton.tintColor = .systemGray
            waveformView.progressBar.progressTintColor = .lightGray
            waveformView.durationLabel.textColor = .lightGray
        }
    }
}
