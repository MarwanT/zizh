//
//  MockRecordsRepository.swift
//  Zizh
//
//  Created by Marwan Tutunji on 04/02/2025.
//

import Combine
import Foundation
@testable import Zizh

final class MockRecordRepository: RecordsRepository {
  var persistedRecords: [Recording] = []

  var fileManagement: any Zizh.FileManagement
  
  init(fileManagement: FileManagement = MockFileManagement()) {
    self.fileManagement = fileManagement
  }
  
  func addRecording(_ recording: Recording) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      persistedRecords.append(recording)
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func fetchRecords() -> AnyPublisher<[Recording], RepositoryError> {
    return Future<[Recording], RepositoryError> { [unowned self] promise in
      promise(.success(self.persistedRecords))
    }.eraseToAnyPublisher()
  }
  
  func deleteRecording(_ recording: Recording) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      persistedRecords = persistedRecords.filter({ current in
        return current.id != recording.id
      })
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
}
