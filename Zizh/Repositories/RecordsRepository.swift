//
//  RecordsRepository.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Combine
import Foundation

protocol RecordsRepository {
  var fileManagement: FileManagement { get }
  func addRecording(_ entity: any RecordDataEntity) -> AnyPublisher<Void, RepositoryError>
  func deleteRecording(_ entity: any RecordDataEntity) -> AnyPublisher<Void, RepositoryError>
  func fetchRecords() -> AnyPublisher<[any RecordDataEntity], RepositoryError>
  func updateRecording(_ entity: any RecordDataEntity) -> AnyPublisher<Void, RepositoryError>
}

enum RepositoryError: Error {
  case deletionFailed(Error)
  case noRecordsFound
  case repositoryDeallocated
  case dataPersistence(DataPersistenceError)
  case unknown(Error)
}
