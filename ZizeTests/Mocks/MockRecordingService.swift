//
//  MockRecordingService.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Combine
@testable import Zize

class MockRecordingService: RecordingService {
  @Published private(set) var isRecording: Bool = false
  var isRecordingPublisher: AnyPublisher<Bool, Never> {
    $isRecording.eraseToAnyPublisher()
  }
  
  func startRecording() {
    isRecording = true
  }
  
  func stopRecording() {
    isRecording = false
  }
}
