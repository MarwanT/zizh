//
//  HomeViewModel.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import AVFoundation
import Foundation
import Combine

extension ViewModel {
  class Home: NSObject, ObservableObject {
    @Published private(set) var isSlowMotion: Bool = false
    @Published private(set) var currentPlayingId: UUID? = nil
   
    @Published var records: [any RecordDataEntity] = []
    @Published var deletionErrorMessage: IdentifiableMessages? = nil
    @Published var audioPlayerAlertMessage: IdentifiableMessages? = nil
    
    @Published var rate: Float = 1/6.0
    
    let recordingViewModel: ViewModel.Recording
    
    private var recordsRepository: (any RecordsRepository)!
    private var mediaPlayer: MediaPlayerService
    private var cancellables: Set<AnyCancellable> = []
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    
    init (recordingService: RecordingService? = nil, recordsRepository: RecordsRepository? = nil, mediaPlayer: MediaPlayerService = AudioPlayerService()) {
      self.recordsRepository = try? recordsRepository ?? AudioRecordsRepository()
      self.mediaPlayer = mediaPlayer
      self.recordingViewModel = ViewModel.Recording(recordingService: recordingService, recordsRepository: self.recordsRepository)
      super.init()
      
      // Observer Recording changes
      recordingViewModel.recordingStateChangePublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state in
          self?.handleRecordingStateChange(state)
        }
        .store(in: &cancellables)
      
      // Observe playback changes
      self.mediaPlayer.status
        .receive(on: DispatchQueue.main)
        .sink { [weak self] status in
          self?.handleMediaPlayerEvents(status)
        }
        .store(in: &cancellables)
    }
    
    func requestPermissions() {
      recordingViewModel.requestPermission()
        .receive(on: DispatchQueue.main)
        .sink { granted in
          // TODO: Handle the granted/ungranted permission to the microphone
        }
        .store(in: &cancellables)
    }
    
    private func handleRecordingStateChange(_ state: ViewModel.Recording.RecordingState) {
      switch state {
      case .finished(let result):
        if case .success = result {
          syncRecordings()
        }
      default:
        break
      }
    }
    
    func syncRecordings() {
      recordsRepository.fetchRecords()
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
          print("Syncing is completed")
        }, receiveValue: { [weak self] recordings in
          self?.records = recordings
        })
        .store(in: &cancellables)
    }
    
    func toggleSlowMotionOn() {
      isSlowMotion = !isSlowMotion
      stopPlayingRecording()
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
                self?.deletionErrorMessage = IdentifiableMessages(message: "Failed to delete recording for repository is deallocated!")
              case .deletionFailed(_):
                print("Failed to delete recording: \(error)")
                self?.deletionErrorMessage = IdentifiableMessages(message: "Failed to delete recording: \(error.localizedDescription)")
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
    
    func handleRecordingTap(_ entity: any RecordDataEntity) {
      togglePlayPause(entity)
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
        }
      } catch {
        print("Failed to update recording: \(error)")
        // Handle the error here
      }
    }
    
    private func togglePlayPause(_ entity: any RecordDataEntity) {
      currentPlayingId != nil ? stopPlayingRecording() : playRecording(entity)
    }
    
    private func playRecording(_ entity: any RecordDataEntity) {
      let absoluteURL = recordsRepository.fileManagement.makeAbsoluteURL(entity.address)
      let result = isSlowMotion ? mediaPlayer.play(absoluteURL, mode: .slowMotion(rate)) : mediaPlayer.play(absoluteURL)
      switch result {
      case .success(_):
        break
      case .failure(let error):
        print("Failed to play recording: \(error)")
      }
    }
    
    func stopPlayingRecording() {
      mediaPlayer.stop()
    }
    
    private func handleMediaPlayerEvents(_ status: MediaPlayerStatus) {
      // Media Player Status Changed
      print("Media Player Status Changed: \(status)")
      switch status {
      case let .playing(url):
        currentPlayingId = recordingFromURL(url)?.id
      case let .paused(url):
        currentPlayingId = recordingFromURL(url)?.id
      case .stopped:
        currentPlayingId = nil
      }
    }
    
    private func recordingFromURL(_ url: URL) -> (any RecordDataEntity)? {
      let relativeURL = try? recordsRepository.fileManagement.makeRelativeURL(url)
      return records.first { $0.address == relativeURL }
    }
  }
}

extension ViewModel.Home {
  class ViewModelHomePreview: ViewModel.Home {
    override func syncRecordings() {
      self.records = [
        RecordingData(duration: 10, name: "Sample Recording", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording2", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording3", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording4", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording5", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording6", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording7", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording8", address: URL(fileURLWithPath: "/zouzou/marwan")),
        RecordingData(duration: 10, name: "Sample Recording9", address: URL(fileURLWithPath: "/zouzou/marwan")),
      ]
    }
  }
  
  static let preview: ViewModel.Home = {
    let viewModel = ViewModelHomePreview()
    return viewModel as ViewModel.Home
  }()
}
