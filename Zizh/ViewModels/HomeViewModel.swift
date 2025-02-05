//
//  HomeViewModel.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Foundation
import Combine

extension ViewModel {
  class Home: ObservableObject {
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var recordings: [Recording] = []
    @Published var deletionErrorMessage: IdentifiableMessages? = nil
    
    private var recordingService: RecordingService!
    private var recordsRepository: any RecordsRepository
    private var cancellables: Set<AnyCancellable> = []
    
    init (recordingService: RecordingService? = nil, recordsRepository: (any RecordsRepository)? = nil) {
      do {
        self.recordsRepository = try recordsRepository ?? AudioRecordsRepository()
        self.recordingService = try recordingService ?? AudioRecordingService()
        
        // Observe isRecording changes
        self.recordingService.isRecordingPublisher
          .receive(on: DispatchQueue.main)
          .assign(to: \.isRecording, on: self)
          .store(in: &cancellables)
        
        // Observe recording finished event
        self.recordingService.recordingFinishedPublisher
          .receive(on: DispatchQueue.main)
          .sink { [weak self] recordingURL in
            Task { @MainActor in
              await self?.addRecording(recordingURL: recordingURL)
            }
          }
          .store(in: &cancellables)
      } catch {
        print("Error Initialising ViewModel: \(error)")
        exit(1)
      }
    }
    
    func requestPermissions() {
      recordingService.requestPermission()
        .receive(on: DispatchQueue.main)
        .sink { granted in
          // TODO: Handle the granted/ungranted permission to the microphone
        }
        .store(in: &cancellables)
    }
    
    func syncRecordings() {
      recordsRepository.fetchRecords()
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
          print("Syncing is completed")
        }, receiveValue: { [weak self] recordings in
          self?.recordings = recordings
        })
        .store(in: &cancellables)
    }
    
    func toggleRecording() {
      if (isRecording) {
        recordingService.stopRecording()
      } else {
        recordingService.startRecording()
      }
    }
    
    func addRecording(recordingURL: URL) async {
      let nameComponents = recordingURL.lastPathComponent.components(separatedBy: CharacterSet(charactersIn: "_") )
      guard let id = UUID(uuidString: nameComponents[0]), let timeInterval = TimeInterval(nameComponents[1]) else {
        print("Recorded file name is not in the correct format")
        return
      }
      let date = Date(timeIntervalSince1970: timeInterval)
      let duration = await self.recordingService.getRecordingDuration(url: recordingURL)
      let newRecording = Recording(id: id, duration: duration, name: date.ISO8601Format(), address: recordingURL)
      self.recordsRepository.addRecording(newRecording)
        .receive(on: DispatchQueue.main)
        .sink { _ in
          // TODO: print and hadle errors here
        } receiveValue: { [weak self] in
          guard let self = self else { return }
          self.syncRecordings()
        }
        .store(in: &cancellables)
    }
    
    func deleteRecording(at offsets: IndexSet) {
      for index in offsets {
        let recording = recordings[index]
        recordsRepository.deleteRecording(recording)
          .receive(on: DispatchQueue.main)
          .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
              switch error {
              case .repositoryDeallocated:
                self?.deletionErrorMessage = IdentifiableMessages(message: "Failed to delete recording for repository is deallocated!")
              case .deletionFailed(let deapError):
                print("Failed to delete recording: \(error)")
                self?.deletionErrorMessage = IdentifiableMessages(message: "Failed to delete recording: \(error.localizedDescription)")
              }
            case .finished:
              break
            }
          } receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.recordings.remove(at: index)
          }
          .store(in: &cancellables)
      }
    }
  }
}
