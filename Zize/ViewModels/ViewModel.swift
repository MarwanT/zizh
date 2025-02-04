//
//  ViewModel.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Foundation
import Combine

class ViewModel: ObservableObject {
  @Published var isRecording: Bool = false
  
  private var recordingService: RecordingService!
  private var cancellables: Set<AnyCancellable> = []
  
  init (recordingService: RecordingService? = nil) {
    do {
      self.recordingService = try recordingService ?? AudioRecordingService()
      self.recordingService.isRecordingPublisher
        .receive(on: DispatchQueue.main)
        .assign(to: \.isRecording, on: self)
        .store(in: &cancellables)
    } catch {
      print("Error Initialising ViewModel: \(error)")
    }
  }
  
  func toggleRecording() {
    if (isRecording) {
      recordingService.stopRecording()
    } else {
      recordingService.startRecording()
    }
  }
  
  func requestPermissions() {
    recordingService.requestPermission()
      .receive(on: DispatchQueue.main)
      .sink { granted in
        // TODO: Handle the granted/ungranted permission to the microphone
      }
      .store(in: &cancellables)
  }
}
