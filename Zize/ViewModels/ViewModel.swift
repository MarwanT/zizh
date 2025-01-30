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
  
  private var recordingService: RecordingService
  private var cancellables: Set<AnyCancellable> = []
  
  init(recordingService: RecordingService) {
    self.recordingService = recordingService
    self.recordingService.isRecordingPublisher
      .receive(on: DispatchQueue.main)
      .assign(to: \.isRecording, on: self)
      .store(in: &cancellables)
  }
  
  func toggleRecording() {
    if (isRecording) {
      recordingService.stopRecording()
    } else {
      recordingService.startRecording()
    }
  }
}
