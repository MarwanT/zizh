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
    @Published var deletionErrorMessage: IdentifiableMessages? = nil
    @Published var audioPlayerAlertMessage: IdentifiableMessages? = nil
    @Published var rate: Float = 1/6.0

    let recordingControlsViewModel: ViewModel.RecordingControls
    let audioListViewModel: ViewModel.AudioList
    private let fileManagement: FileManagement
    private let mediaPlayer: MediaPlayerService
    
    private(set) var currentlyPlayingAudio: (any AudioRecord)? {
      didSet {
        audioListViewModel.highlightedRecording = currentlyPlayingAudio?.id
      }
    }
    private var cancellables: Set<AnyCancellable> = []
    
    init (
      recordingControlsViewModel: ViewModel.RecordingControls? = nil,
      audioListViewModel: ViewModel.AudioList? = nil,
      recordingService: RecordingService? = nil,
      recordsRepository: RecordsRepository? = nil,
      fileManagement: FileManagement = DefaultFileManagement(),
      mediaPlayer: MediaPlayerService = AudioPlayerService()
    ) {
      self.fileManagement = fileManagement
      self.mediaPlayer = mediaPlayer
      let recordsRepository = try? recordsRepository ?? AudioRecordsRepository(fileManagement: fileManagement)
      let recordingService = try? recordingService ?? AudioRecordingService(fileManagement: fileManagement)
      self.audioListViewModel = audioListViewModel ?? ViewModel.AudioList(recordsRepository: recordsRepository)
      self.recordingControlsViewModel = recordingControlsViewModel ?? ViewModel.RecordingControls(recordingService: recordingService, recordsRepository: recordsRepository)
      super.init()
      
      // Observer Recording changes
      self.recordingControlsViewModel.recordingStateChangePublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state in
          self?.handleRecordingStateChange(state)
        }
        .store(in: &cancellables)
      
      // Observe list rows taps
      self.audioListViewModel.tapRecordingPublisher
        .receive(on: DispatchQueue.main)
        .sink { recording in
          self.handleRecordingRowTap(recording)
        }
        .store(in: &cancellables)
      
      // Observe list actions errors
      self.audioListViewModel.alertPublisher
        .receive(on: DispatchQueue.main)
        .assign(to: \.deletionErrorMessage, on: self)
        .store(in: &cancellables)
      
      // Observe playback changes
      self.mediaPlayer.status
        .receive(on: DispatchQueue.main)
        .sink { [weak self] status in
          self?.handleMediaPlayerEvents(status)
        }
        .store(in: &cancellables)
      
      // Observer playback errors
      self.mediaPlayer.alertPublisher
        .receive(on: DispatchQueue.main)
        .assign(to: \.audioPlayerAlertMessage, on: self)
        .store(in: &cancellables)
    }
    
    func requestPermissions() {
      recordingControlsViewModel.requestPermission()
        .receive(on: DispatchQueue.main)
        .sink { granted in
          // TODO: Handle the granted/ungranted permission to the microphone
        }
        .store(in: &cancellables)
    }
    
    private func handleRecordingStateChange(_ state: ViewModel.RecordingControls.RecordingState) {
      switch state {
      case .finished(let result):
        if case .success = result {
          syncRecordings()
            .sink { _ in  } receiveValue: { _ in }
            .store(in: &cancellables)
        }
      default:
        break
      }
    }
    
    func syncRecordings() -> AnyPublisher<Void, ViewModel.AudioList.AudioListError> {
      return audioListViewModel.syncRecordings()
    }
    
    func toggleSlowMotionOn() {
      isSlowMotion = !isSlowMotion
      stopPlayingRecording()
    }
    
    private func handleRecordingRowTap(_ entity: any AudioRecord) {
      if currentlyPlayingAudio?.id == entity.id {
        stopPlayingRecording()
      } else {
        stopPlayingRecording()
        currentlyPlayingAudio = entity
        playRecording(entity)
      }
    }
    
    private func playRecording(_ entity: any AudioRecord) {
      let absoluteURL = fileManagement.makeAbsoluteURL(entity.address)
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
        fallthrough
      case let .paused(url):
        currentlyPlayingAudio = audioListViewModel.recordingFromURL(url)
      case .stopped:
        currentlyPlayingAudio = nil
      }
    }
  }
}
