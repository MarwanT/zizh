//
//  MockRecordingService.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Combine
import Foundation
@testable import Zizh

class MockRecordingService: RecordingService {
  private var fileManagement: FileManagement
  private var fileManager: FileManager
  
  @Published private(set) var isRecording: Bool = false
  var isRecordingPublisher: AnyPublisher<Bool, Never> {
    $isRecording.eraseToAnyPublisher()
  }
  
  @Published private(set) var recordingFinishedURL: URL
  var recordingFinishedPublisher: AnyPublisher<URL, Never> {
    return $recordingFinishedURL.eraseToAnyPublisher()
  }
  
  init(fileManagement: FileManagement = DefaultFileManagement(), fileManager: FileManager = .default) {
    self.fileManagement = fileManagement
    self.fileManager = fileManager
    recordingFinishedURL = self.fileManager.temporaryDirectory
  }
  
  func startRecording() {
    isRecording = true
  }
  
  func stopRecording() {
    isRecording = false
    recordingFinishedURL = self.fileManagement.generateNewRecordingURL()
  }
  
  func requestPermission() -> AnyPublisher<Bool, Never> {
    return Just(true).eraseToAnyPublisher()
  }
  
  func getRecordingDuration(url: URL) async -> TimeInterval {
    return 10
  }
}
