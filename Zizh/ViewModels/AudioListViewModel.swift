//
//  RecordingsListViewModel.swift
//  Zizh
//
//  Created by Marwan Tutunji on 19/02/2025.
//

import Combine
import Foundation

extension ViewModel {
  class AudioList: ObservableObject {
    private let recordsQueue = DispatchQueue(label: "com.zizh.AudioList.recordsQueue")
    @Published var records: [any AudioRecord] = []
    @Published var highlightedRecording: UUID? = nil
    private(set) var alertPublisher: PassthroughSubject<IdentifiableMessages?, Never> = .init()
    
    let tapRecordingPublisher = PassthroughSubject<AudioRecordData, Never>()
    
    private let recordsRepository: RecordsRepository!
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(recordsRepository: (any RecordsRepository)? = nil) {
      self.recordsRepository = try? recordsRepository ?? AudioRecordsRepository()
    }
    
    func syncRecordings() -> AnyPublisher<Void, AudioListError> {
      return recordsRepository.fetchRecords()
        .map({ [weak self] recordings in
          self?.modifyRecordThreadSafely(.setting(recordings))
          return ()
        })
        .mapError({ repoError in
          return .couldNotSyncRecords(repoError)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func modifyRecordThreadSafely(_ action: RecordsDataAction) {
      recordsQueue.sync {
        switch action {
          case .deleting(let id):
          self.records.remove(at: id)
        case .setting(let newRecords):
          self.records = newRecords
        }
      }
    }
    
    func updateRecording(_ recordingId: UUID, name: String) -> AnyPublisher<Void, AudioListError> {
      guard var recording = records.first(where: { $0.id == recordingId }) else {
        return Fail<Void, AudioListError>(error: .recordingNotFound).eraseToAnyPublisher()
      }
      recording.name = name
      return recordsRepository.updateRecording(recording)
        .mapError { error -> AudioListError in
          return .couldNotUpdateRecord(error)
        }
        .flatMap { [weak self] _ -> AnyPublisher<Void, AudioListError> in
          guard let self = self else {
            return Fail<Void, AudioListError>(error: .couldNotUpdateRecord(nil)).eraseToAnyPublisher()
          }
          return self.syncRecordings()
        }
        .eraseToAnyPublisher()
    }
    
    func deleteRecording(at offsets: IndexSet) {
      for index in offsets {
        guard index < records.count else {
          alertPublisher.send(IdentifiableMessages(message: "Failed to delete unrecognized recording"))
          continue
        }
        let recording = records[index]
        recordsRepository.deleteRecording(recording)
          .receive(on: DispatchQueue.main)
          .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
              switch error {
              case .repositoryDeallocated:
                self?.alertPublisher.send(IdentifiableMessages(message: "Failed to delete recording for repository is deallocated!"))
              case .deletionFailed(_):
                print("Failed to delete recording: \(error)")
                self?.alertPublisher.send(IdentifiableMessages(message: "Failed to delete recording: \(error.localizedDescription)"))
              default:
                break
              }
            case .finished:
              guard let self = self else { return }
              self.modifyRecordThreadSafely(.deleting(index))
            }
          } receiveValue: { _ in }
          .store(in: &cancellables)
      }
    }
    
    func handleRecordingTap(_ entity: any AudioRecord) {
      let recordingData: AudioRecordData = AudioRecordData.entityFrom(entity)
      tapRecordingPublisher.send(recordingData)
    }
    
    func recordingFromURL(_ url: URL) -> (any AudioRecord)? {
      let relativeURL = try? recordsRepository.fileManagement.makeRelativeURL(url)
      return records.first { $0.address == relativeURL }
    }
  }
}

extension ViewModel.AudioList {
  enum AudioListError: Error {
    case couldNotSyncRecords(RepositoryError)
    case couldNotUpdateRecord(RepositoryError?)
    case recordingNotFound
    case indexOutOfBounds
  }
  
  enum RecordsDataAction {
    case setting(_ records: [any AudioRecord])
    case deleting(_ index: Int)
  }
}
