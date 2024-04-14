//
//  AudioRecorderView.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 14/04/24.
//

/**
 A custom UIView subclass for audio recording functionality.

 This view handles audio recording using `AVAudioRecorder` and provides methods to start and stop recording,
 monitor recording progress, and send recorded audio messages.

 - Author: Inderpreet Singh
 - Version: 1.0
 */

import UIKit
import AVFoundation

class AudioRecorderView: UIView {

    var audioRecorder: AVAudioRecorder?
    var audioURL: URL?
    var recordingProgress: ((Float) -> Void)?
    var view: UIViewController?
    
    // Message Details
    var conversationID:String?
    var sender:AuthenticatedUser?
    var result: ((Bool, ErrorCode?) -> Void)?

    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .lightGray
        return progressView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()

    private var recordingTimer: Timer?
    private var currentRecordingDuration: TimeInterval = 0.0
    private let maxRecordingDuration: TimeInterval = 30.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        requestMicrophonePermission()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        requestMicrophonePermission()
    }

    private func setupUI() {
        addSubview(progressView)
        addSubview(durationLabel)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            durationLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
            durationLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                // Microphone permission granted, proceed to set up the audio session
                DispatchQueue.main.async {
                    self.setupAudioSession()
                }
            } else {
                // Microphone permission denied, inform the user
                DispatchQueue.main.async {
                    self.showMicrophonePermissionAlert()
                }
            }
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            guard let viewController = view else { return }
            AlerUser().alertUser(viewController: viewController, title: "Error", message: "Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    private func showMicrophonePermissionAlert() {
        guard let viewController = view else { return }
        AlerUser().alertUser(viewController: viewController, title: "Microphone Permission Required", message: "Please enable microphone access in Settings to use this feature.")
    }

    func startRecording() {
        guard AVAudioApplication.recordPermission.granted == .granted else {
            // Handle case where microphone permission is not granted
            showMicrophonePermissionAlert()
            return
        }

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            guard let viewController = view else { return }
            AlerUser().alertUser(viewController: viewController, title: "Error", message: "Documents directory not found")
            return
        }

        let audioFilename = documentsDirectory.appendingPathComponent("recording.m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            // Start recording timer
            startRecordingTimer()

        } catch {
            guard let viewController = view else { return }
            AlerUser().alertUser(viewController: viewController, title: "Error", message: "Error starting recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil

        // Stop recording timer
        stopRecordingTimer()
    }

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.currentRecordingDuration += 0.1
            let progress = Float(self.currentRecordingDuration / self.maxRecordingDuration)
            self.progressView.progress = progress
            self.recordingProgress?(progress)

            if self.currentRecordingDuration >= self.maxRecordingDuration {
                self.stopRecording()
                timer.invalidate()
            }

            self.updateDurationLabel()
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        currentRecordingDuration = 0.0
        progressView.progress = 0.0
        updateDurationLabel()
    }

    private func updateDurationLabel() {
        let formattedDuration = formatTime(timeInterval: currentRecordingDuration)
        durationLabel.text = formattedDuration
    }

    private func formatTime(timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension AudioRecorderView: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let audioURL = recorder.url
            self.audioURL = audioURL
            guard let viewController = view else { return }
            ChatModel().sendAudioMessage(conversationID: conversationID ?? "", sender: sender, audioURL: audioURL) { error in
                if let error = error{
                    AlerUser().alertUser(viewController: viewController, title: "Error", message: error.description)
                }
                self.result?(true, nil)
            }
        } else {
            print("Recording failed")
        }
    }
}
