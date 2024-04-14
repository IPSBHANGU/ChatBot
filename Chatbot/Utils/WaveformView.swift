//
//  WaveformView.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 14/04/24.
//

/**
 Displays a waveform representation of an audio file and provides playback controls.

 - Parameters:
   - audioURL: The URL of the audio file to be loaded and played.
   - view: The view controller context for displaying alerts during operations.
   - playbackProgress: A closure that receives playback progress updates (0.0 to 1.0).

 This view supports loading an audio file from a URL, displaying a waveform visualization of the audio data,
 and enabling playback controls (play, pause, stop).

 ### Example Usage:
 ```swift
 let waveformView = WaveformView(frame: CGRect(x: 0, y: 0, width: 300, height: 150))
 waveformView.audioURL = URL(string: "https://example.com/audio.mp3")
 waveformView.playbackProgress = { progress in
     // Update UI with playback progress (e.g., update progress bar)
     waveformView.progressBar.setProgress(progress, animated: true)
 }
 
 - Author: Inderpreet Singh
 - Version: 1.0
 */

import UIKit
import AVFoundation

class WaveformView: UIView {
    var audioURL: URL? {
        didSet {
            guard let audioURL = audioURL else { return }
            downloadAudioFile(from: audioURL)
        }
    }
    var view:UIViewController?
    
    var audioPlayer: AVAudioPlayer?
    var playbackProgress: ((Float) -> Void)?
    
    // UI Elements
    let progressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .lightGray
        return progressView
    }()
    
    let playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .systemGray
        return button
    }()
    
    let pauseButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        button.tintColor = .systemGray
        button.isHidden = true
        return button
    }()
    
    let durationLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        addSubview(progressBar)
        addSubview(playButton)
        addSubview(pauseButton)
        
        // Create and configure the durationLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.textColor = .darkGray
        durationLabel.font = UIFont.systemFont(ofSize: 10)
        durationLabel.text = "00:00 / 00:00"
        addSubview(durationLabel)
        
        playButton.layer.zPosition = 1
        pauseButton.layer.zPosition = 1
        
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            
            playButton.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor),
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            
            pauseButton.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor),
            pauseButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            
            durationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            durationLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 5)
        ])
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
    }
    
    func play() {
        audioPlayer?.play()
        updatePlaybackState(isPlaying: true)
        startUpdateTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        updatePlaybackState(isPlaying: false)
        stopUpdateTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        updatePlaybackState(isPlaying: false)
        resetProgress()
        stopUpdateTimer()
        setupDuration(didStoped: true)
    }
    
    private func downloadAudioFile(from url: URL) {
        guard let view = view else {return}
        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempURL, response, error) in
            guard let self = self else { return }
            
            if let tempURL = tempURL {
                do {
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                    
                    // Remove existing file at destination if it exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    
                    DispatchQueue.main.async {
                        self.loadAudioFile(from: destinationURL)
                    }
                } catch {
                    AlerUser().alertUser(viewController: view, title: "Error", message: "Error moving downloaded file: \(error)")
                }
            } else {
                AlerUser().alertUser(viewController: view, title: "Error", message: "Error downloading audio file: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        task.resume()
    }
    
    private func loadAudioFile(from url: URL) {
        guard let view = view else {return}
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
                try audioFile.read(into: pcmBuffer!)
                
                DispatchQueue.main.async {
                    self.drawWaveform(buffer: pcmBuffer!, channelCount: audioFile.processingFormat.channelCount)
                }
                
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
            } catch {
                AlerUser().alertUser(viewController: view, title: "Error", message: "Error loading audio file: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatTime(timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updatePlaybackState(isPlaying: Bool) {
        playButton.isHidden = isPlaying
        pauseButton.isHidden = !isPlaying
    }
    
    func setupDuration(didStoped:Bool = false){
        if let player = audioPlayer {
            let currentDuration = formatTime(timeInterval: player.currentTime)
            let totalDuration = formatTime(timeInterval: player.duration)
            if didStoped {
                durationLabel.text = "00:00 / \(totalDuration)"
            } else {
                durationLabel.text = "\(currentDuration) / \(totalDuration)"
            }
        }
    }
    
    private var updateTimer: Timer?
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            let currentTime = Float(player.currentTime)
            let duration = Float(player.duration)
            let progress = currentTime / duration
            self.playbackProgress?(progress)
            if currentTime >= duration {
                self.stop()
                timer.invalidate()
            }
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc private func playButtonTapped() {
        guard let view = view else {return}
        guard let audioURL = audioURL else { return }
        if audioPlayer == nil {
            downloadAudioFile(from: audioURL)
            AlerUser().alertUser(viewController: view, title: "Waiting for Media", message: "Downloading Audio File")
        } else {
            play()
        }
    }
    
    @objc private func pauseButtonTapped() {
        pause()
    }
    
    private func drawWaveform(buffer: AVAudioPCMBuffer, channelCount: AVAudioChannelCount) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(UIColor.blue.cgColor)
        
        let width = bounds.width
        let height = bounds.height
        let sampleCount = buffer.frameLength
        let step = Int(sampleCount) / Int(width)
        
        context.move(to: CGPoint(x: 0, y: height / 2))
        
        let channelData = buffer.floatChannelData
        
        for i in stride(from: 0, to: Int(sampleCount), by: step) {
            let x = CGFloat(i) * width / CGFloat(sampleCount)
            var y: CGFloat = 0.0
            
            if channelCount == 1 {
                y = CGFloat(channelData?[0][i] ?? 0.0) * height / 2 + height / 2
            } else if channelCount >= 2 {
                var sum: Float = 0.0
                for channel in 0..<Int(channelCount) {
                    sum += channelData?[channel][i] ?? 0.0
                }
                let average = sum / Float(channelCount)
                y = CGFloat(average) * height / 2 + height / 2
            }
            
            context.addLine(to: CGPoint(x: x, y: y))
        }
        
        context.strokePath()
    }
    
    private func resetProgress() {
        progressBar.setProgress(0.0, animated: false)
    }
}

extension WaveformView: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}
