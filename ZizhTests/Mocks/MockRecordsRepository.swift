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
  private let recordsQueue = DispatchQueue(label: "com.zizh.mock.recordsQueue")
  var persistedRecords: [AudioRecordData] = []
  var callBehavior: Behavior = .succeed

  var fileManagement: any Zizh.FileManagement
  
  init(fileManagement: FileManagement = MockFileManagement()) {
    self.fileManagement = fileManagement
  }
  
  func addRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      if case let .fail(error) = callBehavior {
        promise(.failure(error))
        return
      }
      let recordData: AudioRecordData = AudioRecordData.entityFrom(entity)
      persistedRecords.append(recordData)
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func fetchRecords() -> AnyPublisher<[any AudioRecord], RepositoryError> {
    return Future<[any AudioRecord], RepositoryError> { [unowned self] promise in
      if case let .fail(error) = callBehavior {
        promise(.failure(error))
        return
      }
      promise(.success(self.persistedRecords))
    }.eraseToAnyPublisher()
  }
  
  func deleteRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [unowned self] promise in
      if case let .fail(error) = callBehavior {
        promise(.failure(error))
        return
      }
      persistedRecords = persistedRecords.filter({ current in
        return current.id != entity.id
      })
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func updateRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    let updated: AudioRecordData = AudioRecordData.entityFrom(entity)
    return Deferred {
      Future { [weak self] promise in
        if case let .fail(error) = self?.callBehavior {
          promise(.failure(error))
          return
        }
        Task { [weak self] in
          self?.updateRecords(updated)
          promise(.success(()))
        }
      }
    }.eraseToAnyPublisher()
  }
  
  private func updateRecords(_ record: AudioRecordData) {
    recordsQueue.sync {
      if let index = persistedRecords.firstIndex(where: { $0.id == record.id }) {
        persistedRecords[index] = record
      } else {
        persistedRecords.append(record)
      }
    }
  }
}

extension MockRecordRepository {
  enum Behavior {
    case succeed
    case fail(RepositoryError)
  }
}
