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
  var persistedRecords: [any RecordDataEntity] = []

  var fileManagement: any Zizh.FileManagement
  
  init(fileManagement: FileManagement = MockFileManagement()) {
    self.fileManagement = fileManagement
  }
  
  func addRecording(_ entity: any RecordDataEntity) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      persistedRecords.append(entity)
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func fetchRecords() -> AnyPublisher<[any RecordDataEntity], RepositoryError> {
    return Future<[any RecordDataEntity], RepositoryError> { [unowned self] promise in
      promise(.success(self.persistedRecords))
    }.eraseToAnyPublisher()
  }
  
  func deleteRecording(_ entity: any RecordDataEntity) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      persistedRecords = persistedRecords.filter({ current in
        return current.id != entity.id
      })
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
}
