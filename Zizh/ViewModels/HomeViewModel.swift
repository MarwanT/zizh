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
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isSlowMotion: Bool = false
    @Published private(set) var isPlaying: Bool = false
    
    @Published var recordings: [Recording] = []
    @Published var deletionErrorMessage: IdentifiableMessages? = nil
    @Published var audioPlayerAlertMessage: IdentifiableMessages? = nil
    
    @Published var rate: Float = 1/6.0
    
    private var recordingService: RecordingService!
    private var recordsRepository: any RecordsRepository
    private var mediaPlayer: MediaPlayerService
    private var cancellables: Set<AnyCancellable> = []
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    
    init (recordingService: RecordingService? = nil, recordsRepository: (any RecordsRepository)? = nil, mediaPlayer: MediaPlayerService = AudioPlayerService()) {
      do {
        self.recordsRepository = try recordsRepository ?? AudioRecordsRepository()
        self.recordingService = try recordingService ?? AudioRecordingService()
        self.mediaPlayer = mediaPlayer
        super.init()
        
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
        
        // Observe playback changes
        mediaPlayer.status
          .receive(on: DispatchQueue.main)
          .sink { [weak self] status in
            self?.handleMediaPlayerEvents(status)
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
    
    func toggleSlowMotionOn() {
      isSlowMotion = !isSlowMotion
      stopPlayingRecording()
    }
    
    func addRecording(recordingURL: URL) async {
      guard let (id, timeInterval) = recordsRepository.fileManagement.extractRecordingInfo(from: recordingURL) else {
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
              case .deletionFailed(_):
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
    
    func handleRecordingTap(_ recording: Recording) {
      togglePlayPause(at: recording.address)
    }
    
    private func togglePlayPause(at url: URL) {
      isPlaying ? stopPlayingRecording() : playRecording(at: url)
    }
    
    private func playRecording(at url: URL) {
      let absoluteURL = recordsRepository.fileManagement.makeAbsoluteURL(url)
      let result = isSlowMotion ? mediaPlayer.play(absoluteURL, mode: .slowMotion(rate)) : mediaPlayer.play(absoluteURL)
      switch result {
      case .success(let success):
        isPlaying = true
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
      case .paused, .stopped:
        isPlaying = false
      default:
        break
      }
    }
  }
}

extension ViewModel.Home {
  class ViewModelHomePreview: ViewModel.Home {
    override func syncRecordings() {
      self.recordings = [
        Recording(duration: 10, name: "Sample Recording", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording2", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording3", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording4", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording5", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording6", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording7", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording8", address: URL(fileURLWithPath: "/zouzou/marwan")),
        Recording(duration: 10, name: "Sample Recording9", address: URL(fileURLWithPath: "/zouzou/marwan")),
      ]
    }
  }
  
  static let preview: ViewModel.Home = {
    let viewModel = ViewModelHomePreview()
    return viewModel as ViewModel.Home
  }()
}
