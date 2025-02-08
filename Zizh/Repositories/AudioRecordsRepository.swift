//
//  AudioRepository.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Combine
import Foundation

class AudioRecordsRepository: RecordsRepository {
  private var dataPersistence: DataPersistenceService
  private(set) var fileManagement: FileManagement
  
  private var cancellables: Set<AnyCancellable> = []
  
  init(dataPersistence: DataPersistenceService? = nil, fileManagement: FileManagement = DefaultFileManagement()) throws {
    self.dataPersistence = try dataPersistence ?? SwiftDataService()
    self.fileManagement = fileManagement
  }
  
  func addRecording(_ recording: Recording) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [weak self] promise in
      guard let self = self else {
        promise(.failure(.repositoryDeallocated))
        return
      }
      makeAddressRelativeIfNeeded(recording)
      Task { @MainActor in
        self.dataPersistence.add(item: recording)
          .receive(on: DispatchQueue.main)
          .sink { completion in
            switch completion {
            case .failure(let error):
              print("Error adding recording: \(error)")
            case .finished:
              break
            }
          } receiveValue: {
            promise(.success(()))
          }
          .store(in: &(self.cancellables))
      }
    }.eraseToAnyPublisher()
  }
  
  func deleteRecording(_ recording: Recording) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [weak self] promise in
      guard let self = self else {
        promise(.failure(.repositoryDeallocated))
        return
      }
      Task { @MainActor in
        self.dataPersistence.remove(item: recording)
          .receive(on: DispatchQueue.main)
          .sink { completion in
            switch completion {
            case .failure(let error):
              print("Error deleting recording: \(error)")
            case .finished:
              break
            }
          } receiveValue: {
            // TODO: Delete the audio file
            self.fileManagement.deleteRecording(at: recording.address)
            promise(.success(()))
          }
          .store(in: &(self.cancellables))
      }
    }.eraseToAnyPublisher()
  }
  
  func fetchRecords() -> AnyPublisher<[Recording], RepositoryError> {
    return Future<[Recording], RepositoryError> { [weak self] promise in
      guard let self = self else {
        promise(.failure(.repositoryDeallocated))
        return
      }
      Task { @MainActor in
        let sorting = Sorting<Recording>(\Recording.createdAt, order: .reverse)
        self.dataPersistence.fetchAll(Recording.self, sortBy: [sorting])
          .receive(on: DispatchQueue.main)
          .sink { completion in
            switch completion {
            case .failure(let error):
              print("Error fetching recordings: \(error)")
            case .finished:
              break
            }
          } receiveValue: { recordings in
            promise(.success(recordings))
          }
          .store(in: &(self.cancellables))
        
      }
    }.eraseToAnyPublisher()
  }
  
  private func makeAddressRelativeIfNeeded(_ recording: Recording) {
    guard !fileManagement.isRelativeURL(recording.address) else {
      return
    }
    do {
      let relativeURL = try fileManagement.makeRelativeURL(recording.address)
      recording.address = relativeURL
    } catch {
      print("Fail to make address relative: \(error)")
    }
  }
}
