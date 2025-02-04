//
//  MockRecordsRepository.swift
//  Zize
//
//  Created by Marwan Tutunji on 04/02/2025.
//

import Combine
import Foundation
@testable import Zize

final class MockRecordRepository: RecordsRepository {
  var persistedRecords: [Recording] = []
  
  var temporaryRecordingURL: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("temp.m4a")
  }
  
  var persistedRecordingsURL: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("AudioRecordings", isDirectory: true)
  }
  
  func fetchRecords() -> AnyPublisher<[Recording], Never> {
    return Just(persistedRecords).eraseToAnyPublisher()
  }
  
  func generateNewRecordingURL() -> URL {
    return FileManager.default.temporaryDirectory
      .appendingPathComponent("AudioRecordings")
      .appendingPathComponent("newRecortd.m4a")
  }
}
