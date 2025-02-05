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
  @Published private(set) var isRecording: Bool = false
  var isRecordingPublisher: AnyPublisher<Bool, Never> {
    $isRecording.eraseToAnyPublisher()
  }
  
  @Published private(set) var recordingFinishedURL: URL
  var recordingFinishedPublisher: AnyPublisher<URL, Never> {
    return $recordingFinishedURL.eraseToAnyPublisher()
  }
  
  init(recordsRepository: any RecordsRepository = MockRecordRepository()) {
    recordingFinishedURL = FileManager.default.temporaryDirectory
  }
  
  func startRecording() {
    isRecording = true
  }
  
  func stopRecording() {
    isRecording = false
  }
  
  func requestPermission() -> AnyPublisher<Bool, Never> {
    return Just(true).eraseToAnyPublisher()
  }
}
