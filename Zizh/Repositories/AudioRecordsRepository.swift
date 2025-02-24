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
  
  func addRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    var sanitizedData = entity
    sanitizedData.address = makeAddressRelativeIfNeeded(entity.address)
    return Future<Void, RepositoryError> { [weak self] promise in
      guard let self = self else {
        promise(.failure(.repositoryDeallocated))
        return
      }
      Task { @MainActor in
        let recording: Recording = Recording.entityFrom(sanitizedData)
        self.dataPersistence.add(item: recording)
          .receive(on: DispatchQueue.main)
          .sink { completion in
            switch completion {
            case .failure(let error):
              print("Error adding recording: \(error)")
              promise(.failure(.dataPersistence(error)))
            case .finished:
              promise(.success(()))
            }
          } receiveValue: {
            
          }
          .store(in: &(self.cancellables))
      }
    }.eraseToAnyPublisher()
  }
  
  func updateRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    Future { [weak self] promise in
      Task { @MainActor in
        guard let self else {
          promise(.failure(.repositoryDeallocated))
          return
        }
        
        do {
          let recordId = entity.id
          let predicate = #Predicate<Recording> { $0.id == recordId }
          let recordings = try await self.dataPersistence.fetch(Recording.self, predicate: predicate, sortBy: [])
            .values
            .first(where: { _ in true }) ?? []
          guard let recording = recordings.first else {
            throw RepositoryError.noRecordsFound
          }
          recording.name = entity.name
          recording.duration = entity.duration
          recording.address = entity.address
          try await self.dataPersistence.update(item: recording)
            .mapError { RepositoryError.unknown($0) }
            .values
            .first(where: { _ in true })
          promise(.success(()))
        } catch {
          promise(.failure(error as? RepositoryError ?? .unknown(error)))
        }
      }
    }
    .eraseToAnyPublisher()
  }
  
  func deleteRecording(_ entity: any AudioRecord) -> AnyPublisher<Void, RepositoryError> {
    return Future<Void, RepositoryError> { [weak self] promise in
      guard let self = self else {
        promise(.failure(.repositoryDeallocated))
        return
      }
      Task { @MainActor in
        let recordingId = entity.id
        let predicate = #Predicate<Recording> { $0.id == recordingId }
        self.dataPersistence.fetch(Recording.self, predicate: predicate, sortBy: [])
          .receive(on: DispatchQueue.main)
          .tryMap { recordings in
            guard let recording = recordings.first else {
              throw RepositoryError.noRecordsFound
            }
            return recording
          }
          .mapError { error -> RepositoryError in
            return error as? RepositoryError ?? .unknown(error)
          }
          .flatMap { [weak self] recording -> AnyPublisher<Void, RepositoryError> in
            guard let self = self else {
              return Fail(error: .repositoryDeallocated).eraseToAnyPublisher()
            }
            return self.dataPersistence.remove(item: recording)
              .mapError { error -> RepositoryError in
                return .dataPersistence(error)
              }
              .handleEvents(receiveCompletion: { completion in
                if case .finished = completion {
                  self.fileManagement.deleteRecording(at: recording.address)
                }
              })
              .eraseToAnyPublisher()
          }
          .sink { completion in
            switch completion {
            case .failure(let error):
              promise(.failure(error))
            case .finished:
              promise(.success(()))
            }
          } receiveValue: { _ in }
          .store(in: &(self.cancellables))
      }
    }.eraseToAnyPublisher()
  }
  
  func fetchRecords() -> AnyPublisher<[any AudioRecord], RepositoryError> {
    return Future<[any AudioRecord], RepositoryError> { [weak self] promise in
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
            promise(.success(recordings.map { AudioRecordData.entityFrom($0) as AudioRecordData }))
          }
          .store(in: &(self.cancellables))
        
      }
    }.eraseToAnyPublisher()
  }
  
  private func makeAddressRelativeIfNeeded(_ url: URL) -> URL {
    guard !fileManagement.isRelativeURL(url) else {
      return url
    }
    do {
      let relativeURL = try fileManagement.makeRelativeURL(url)
      return relativeURL
    } catch {
      print("Fail to make address relative: \(error)")
      return url
    }
  }
}
