//
//  RecordingService.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import AVFoundation
import Combine
import Foundation

protocol RecordingService {
  var isRecordingPublisher: AnyPublisher<Bool, Never> { get }
  var recordingFinishedPublisher: AnyPublisher<URL, Never> { get }
  func startRecording()
  func stopRecording()
  func requestPermission() -> AnyPublisher<Bool, Never>
  func getRecordingDuration(url: URL) async -> TimeInterval
}

class AudioRecordingService: NSObject, RecordingService {
  @Published private(set) var isRecording: Bool = false
  private var recordingFinishedSubject: PassthroughSubject<URL, Never> = .init()
  private var recorder: AVAudioRecorder
  private var fileManager: FileManagement
  private var permissionsService: PermissionsService
  
  init(recorder: AVAudioRecorder? = nil,
       fileManager: FileManagement = DefaultFileManagement(),
       permissionService: PermissionsService = PermissionsService()) throws {
    self.fileManager = fileManager
    self.recorder = try recorder ?? {
      let generatedRecorder = try AVAudioRecorder(
        url: fileManager.temporaryRecordingURL,
        settings: [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 44100.0,
          AVNumberOfChannelsKey: 2,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
      return generatedRecorder
    }()
    self.permissionsService = permissionService
    super.init()
    self.recorder.delegate = self
  }
  
  var isRecordingPublisher: AnyPublisher<Bool, Never> {
    $isRecording.eraseToAnyPublisher()
  }
  var recordingFinishedPublisher: AnyPublisher<URL, Never> {
    recordingFinishedSubject.eraseToAnyPublisher()
  }
  private var audioSession: AVAudioSession {
    return AVAudioSession.sharedInstance()
  }
  
  func startRecording() {
    do {
      try audioSession.setCategory(.playAndRecord)
      try audioSession.setActive(true, options: [])
      
      isRecording = true
      recorder.record()
    } catch {
      // TODO: Handle the error correctly, inform the user
      print("Error starting audio file due to session failure: \(error)")
    }
  }
  
  func stopRecording() {
    recorder.stop()
  }
  
  func requestPermission() -> AnyPublisher<Bool, Never> {
    return self.permissionsService.requestMicrophonePermission()
  }
  
  func getRecordingDuration(url: URL) async -> TimeInterval {
    let asset = AVURLAsset(url: url)
    let duration = try? await asset.load(.duration)
    return CMTimeGetSeconds(duration ?? CMTime(seconds: 0, preferredTimescale: 1))
  }
  
  private func moveRecordingToDurableLocation() {
    guard let durableFileURL = fileManager.moveTemporaryRecordingToPersistedLocation(url: recorder.url) else {
      return
    }
    recordingFinishedSubject.send(durableFileURL)
  }
}

// MARK: AVAudioRecorderDelegate Implementation
extension AudioRecordingService: AVAudioRecorderDelegate {
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    isRecording = false
    if flag {
      moveRecordingToDurableLocation()
    }
  }
}
