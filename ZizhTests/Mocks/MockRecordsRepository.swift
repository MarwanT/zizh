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
  var persistedRecords: [any AudioRecord] = []

  var fileManagement: any Zizh.FileManagement
  
  init(fileManagement: FileManagement = MockFileManagement()) {
    self.fileManagement = fileManagement
  }
  
  func addRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      persistedRecords.append(entity)
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func fetchRecords() -> AnyPublisher<[any AudioRecord], RepositoryError> {
    return Future<[any AudioRecord], RepositoryError> { [unowned self] promise in
      promise(.success(self.persistedRecords))
    }.eraseToAnyPublisher()
  }
  
  func deleteRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      persistedRecords = persistedRecords.filter({ current in
        return current.id != entity.id
      })
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func updateRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    guard let index = persistedRecords.firstIndex(where: { $0.id == entity.id }) else {
      return addRecording(AudioRecordData.entityFrom(entity) as AudioRecordData)
    }
    persistedRecords[index] = entity
    return Future<Void, RepositoryError> { promise in
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
}
