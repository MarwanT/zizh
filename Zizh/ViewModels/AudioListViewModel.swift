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
          self?.records = recordings
          return ()
        })
        .mapError({ repoError in
          return .couldNotSyncRecords(repoError)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func updateRecording(_ recordingId: UUID, name: String) async {
      guard var recording = records.first(where: { $0.id == recordingId }) else {
        return
      }
      recording.name = name
      do {
        // Convert the publisher to an async sequence and await its completion
        try await recordsRepository.updateRecording(recording)
          .mapError { $0 as Error } // Convert RepositoryError to Error
          .values
          .first(where: { _ in true }) // Wait for the first value (completion)
        
        // Ensure UI updates are on the main thread
        await MainActor.run {
          syncRecordings()
            .sink { _ in  } receiveValue: { _ in }
            .store(in: &cancellables)
        }
      } catch {
        print("Failed to update recording: \(error)")
        // Handle the error here
      }
    }
    
    func deleteRecording(at offsets: IndexSet) {
      for index in offsets {
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
              self.records.remove(at: index)
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
  }
}
