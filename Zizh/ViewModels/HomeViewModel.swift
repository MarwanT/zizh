//
//  HomeViewModel.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
  @Published private(set) var isRecording: Bool = false
  @Published private(set) var recordings: [Recording] = []
  @Published var deletionErrorMessage: IdentifiableMessages? = nil
  
  private var recordingService: RecordingService!
  private var recordsRepository: any RecordsRepository
  private var cancellables: Set<AnyCancellable> = []
  
  init (recordingService: RecordingService? = nil, recordsRepository: (any RecordsRepository)? = nil) {
    do {
      self.recordsRepository = recordsRepository ?? AudioRecordsRepository()
      self.recordingService = try recordingService ?? AudioRecordingService(recordsRepository: self.recordsRepository)
      
      // Observe isRecording changes
      self.recordingService.isRecordingPublisher
        .receive(on: DispatchQueue.main)
        .assign(to: \.isRecording, on: self)
        .store(in: &cancellables)
      
      // Observe recording finished event
      self.recordingService.recordingFinishedPublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
          self?.syncRecordings()
        }
        .store(in: &cancellables)
    } catch {
      print("Error Initialising ViewModel: \(error)")
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
      .sink { recordings in
        self.recordings = recordings
      }
      .store(in: &cancellables)
  }
  
  func toggleRecording() {
    if (isRecording) {
      recordingService.stopRecording()
    } else {
      recordingService.startRecording()
    }
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
