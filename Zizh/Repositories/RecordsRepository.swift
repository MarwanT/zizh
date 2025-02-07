//
//  RecordsRepository.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Combine
import Foundation

protocol RecordsRepository {
  var fileManager: FileManagement { get }
  func addRecording(_ recording: Recording) -> AnyPublisher<Void, RepositoryError>
  func deleteRecording(_ recording: Recording) -> AnyPublisher<Void, RepositoryError>
  func fetchRecords() -> AnyPublisher<[Recording], RepositoryError>
}

enum RepositoryError: Error {
    case repositoryDeallocated
    case deletionFailed(Error)
}
