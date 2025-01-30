//
//  RecordingService.swift
//  Zize
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
}

class AudioRecordingService: NSObject, RecordingService {
  @Published private(set) var isRecording: Bool = false
  private var recordingFinishedSubject: PassthroughSubject<URL, Never> = .init()
  private var recorder: AVAudioRecorder
  
  init(recorder: AVAudioRecorder? = nil) throws {
    self.recorder = try recorder ?? {
      let generatedRecorder = try AVAudioRecorder(
        url: AudioRecordingService.temporaryRecordingFileURL,
        settings: [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 44100.0,
          AVNumberOfChannelsKey: 2,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
      return generatedRecorder
    }()
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
  
  private func moveRecordingToDurableLocation() {
    let temporaryURL = recorder.url
    let durableFileURL = AudioRecordingService.durableRecordingFileURL
    do {
      try FileManager.default.moveItem(at: temporaryURL, to: durableFileURL)
      recordingFinishedSubject.send(durableFileURL)
    } catch {
      // TODO: Handle the error correctly, inform the user
      print("Error moving audio file: \(error)")
    }
  }
}

// MARK: Static Methods
extension AudioRecordingService {
  private static var temporaryRecordingFileURL: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("temp.m4a")
  }
  
  private static var durableRecordingFileURL: URL {
    let now = Date().ISO8601Format()
    return FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("\(now).m4a")
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
