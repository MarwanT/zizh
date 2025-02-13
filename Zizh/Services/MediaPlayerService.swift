//
//  MediaPlayerService.swift
//  Zizh
//
//  Created by Marwan Tutunji on 13/02/2025.
//

import AVFoundation
import Combine
import Foundation

protocol MediaPlayerService: AnyObject {
  var status: AnyPublisher<MediaPlayerStatus, Never> { get }
  func play(_ url: URL) -> Result<Bool, MediaPlayerError>
  func play(_ url: URL, mode: PlayMode) -> Result<Bool, MediaPlayerError>
  func stop()
}

enum PlayMode {
  case normal
  case slowMotion(_ rate: Float)
}

enum MediaPlayerStatus {
  case playing
  case paused
  case stopped
}

enum MediaPlayerError: Error {
  case invalidMediaAddress
  case playbackFailed
  case serviceDeallocated
}


// MARK: ===========================  Implementation  ==============================


class AudioPlayerService: NSObject, MediaPlayerService {
  private var fileManager: FileManager
  
  private var audioPlayer: AVAudioPlayer?
  private var audioEngine: AVAudioEngine?
  private var audioPlayerNode: AVAudioPlayerNode?
  
  @Published private(set) var currentStatus: MediaPlayerStatus = .stopped
  
  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }
  
  var status: AnyPublisher<MediaPlayerStatus, Never> {
    return $currentStatus.eraseToAnyPublisher()
  }
  
  func play(_ url: URL) -> Result<Bool, MediaPlayerError> {
    return play(url, mode: .normal)
  }
  
  func play(_ url: URL, mode: PlayMode = .normal) -> Result<Bool, MediaPlayerError> {
    stop()
    guard validateURL(url) else {
      return .failure(.invalidMediaAddress)
    }
    
    do {
      try configureAudioSession()
      switch mode {
      case .normal:
        try playNormalSpeed(url)
      case .slowMotion(let rate):
        try playSlowMotion(url, for: rate)
      }
      currentStatus = .playing
      return .success(true)
    } catch {
      return .failure(.playbackFailed)
    }
  }
  
  func stop() {
    stopRecordingPlayingNormally()
    stopRecordingPlayingInSlowMotion()
    currentStatus = .stopped
  }
  
  private func playNormalSpeed(_ url: URL) throws {
    audioPlayer = try AVAudioPlayer(contentsOf: url)
    guard let audioPlayer = audioPlayer else { return }
    audioPlayer.delegate = self
    audioPlayer.prepareToPlay()
    audioPlayer.play()
  }
  
  private func playSlowMotion(_ url: URL, for rate: Float) throws {
    audioEngine = AVAudioEngine()
    audioPlayerNode = AVAudioPlayerNode()
    guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode else { return }
    
    let timePitch = AVAudioUnitTimePitch()
    timePitch.rate = rate // 4x slowdown
    timePitch.pitch = log2(rate) * 1200 // Adjust pitch to avoid robotic sound
    print("Rate: \(rate) ; Pitch: \(timePitch.pitch)")
    
    // Attach all nodes first
    audioEngine.attach(audioPlayerNode)
    audioEngine.attach(timePitch)
    
    // Connect nodes in sequence
    audioEngine.connect(audioPlayerNode, to: timePitch, format: nil)
    audioEngine.connect(timePitch, to: audioEngine.mainMixerNode, format: nil)
    
    
    guard let audioFile = try? AVAudioFile(forReading: url) else {
      print("Failed to load audio file.")
      throw NSError(domain: "Audio File Error", code: -1)
    }
    
    // Start engine first
    do {
      try audioEngine.start()
    
      // Schedule audio after engine is running
      audioPlayerNode.scheduleFile(audioFile, at: nil) { [weak self] in
        self?.audioEngine?.stop()
        self?.currentStatus = .stopped
      }
      
      // Add minimal hardware sync delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
        audioPlayerNode.play()
      }
    } catch {
      print("Engine start failed: \(error)")
      throw error
    }
  }
  
  private func stopRecordingPlayingNormally() {
    guard let audioPlayer = audioPlayer else {
      return
    }
    audioPlayer.stop()
    self.audioPlayer = nil
  }
  
  private func stopRecordingPlayingInSlowMotion() {
    guard audioEngine != nil, audioPlayerNode != nil else {
      return
    }
    audioPlayerNode?.stop()
    audioEngine?.stop()
    audioEngine = nil
    audioPlayerNode = nil
  }
  
  private func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Set the audio session category to play and record, and default to speaker
      try audioSession.setCategory(.playAndRecord, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
      // Activate the audio session
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to set up audio session: \(error.localizedDescription)")
      throw error
    }
  }
  
  internal func validateURL(_ url: URL) -> Bool {
    return fileManager.fileExists(atPath: url.path())
  }
}


extension AudioPlayerService: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.currentStatus = .stopped
    self.audioPlayer = nil
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    self.currentStatus = .stopped
    self.audioPlayer = nil
//    self.audioPlayerAlertMessage = IdentifiableMessages(message: "Audio player audio decoding error occurred")
  }

  func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
    self.currentStatus = .paused
    print("Audio player was Interrupted")
  }

  func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
    self.currentStatus = .playing
    print("Audio player interruption ended")
  }
}
