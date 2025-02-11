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
    
    @Published var rate: Float = 1/8.0
    
    private var recordingService: RecordingService!
    private var recordsRepository: any RecordsRepository
    private var cancellables: Set<AnyCancellable> = []
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    
    init (recordingService: RecordingService? = nil, recordsRepository: (any RecordsRepository)? = nil) {
      do {
        self.recordsRepository = try recordsRepository ?? AudioRecordsRepository()
        self.recordingService = try recordingService ?? AudioRecordingService()
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
    
    func handleRecordingTap(_ recording: Recording) {
      togglePlayPause(at: recording.address)
    }
    
    private func togglePlayPause(at url: URL) {
      isPlaying ? stopPlayingRecording() : playRecording(at: url)
    }
    
    private func playRecording(at url: URL) {
      stopPlayingRecording()
      
      let absoluteURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.path())
      guard FileManager.default.fileExists(atPath: absoluteURL.path()) else {
        self.audioPlayerAlertMessage = IdentifiableMessages(message: "Audio file does not exist!")
        return
      }
      
      configureAudioSession()
      if isSlowMotion {
        playRecordingInSlowMotion(at: absoluteURL)
      } else {
        playRecordingNormally(at: absoluteURL)
      }
    }
    
    private func playRecordingNormally(at url: URL) {
      do {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer!.delegate = self
        audioPlayer!.prepareToPlay()
        audioPlayer!.play()
      } catch {
        print("Error playing recording: \(error.localizedDescription)")
      }
    }
    
    private func playRecordingInSlowMotion(at url: URL) {
      audioEngine = AVAudioEngine()
      audioPlayerNode = AVAudioPlayerNode()
      guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode else { return }
      
      let timePitch = AVAudioUnitTimePitch()
      timePitch.rate = rate // 4x slowdown
      timePitch.pitch = log2(rate) * 1200 // Adjust pitch to avoid robotic sound
      print("Rate: \(rate) ; Pitch: \(timePitch.pitch)")
      
      // Attach all nodes first
      audioEngine.attach(audioPlayerNode)
      audioEngine.attach(timePitch)
      
      // Connect nodes in sequence
      audioEngine.connect(audioPlayerNode, to: timePitch, format: nil)
      audioEngine.connect(timePitch, to: audioEngine.mainMixerNode, format: nil)
      
      
      guard let audioFile = try? AVAudioFile(forReading: url) else {
        print("Failed to load audio file.")
        return
      }
      
      // Start engine first
      do {
        try audioEngine.start()
        
        // Schedule audio after engine is running
        audioPlayerNode.scheduleFile(audioFile, at: nil) { [weak self] in
          self?.audioEngine?.stop()
        }
        
        // Add minimal hardware sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
          audioPlayerNode.play()
        }
      } catch {
        print("Engine start failed: \(error)")
      }
    }
    
    private func stopPlayingRecording() {
      stopRecordingPlayingNormally()
      stopRecordingPlayingInSlowMotion()
    }
    
    private func stopRecordingPlayingNormally() {
      guard let audioPlayer = audioPlayer else {
        return
      }
      audioPlayer.stop()
      self.audioPlayer = nil
    }
    
    private func stopRecordingPlayingInSlowMotion() {
      guard audioEngine != nil, audioPlayerNode != nil else {
        return
      }
      audioPlayerNode?.stop()
      try? audioEngine?.stop()
      audioEngine = nil
      audioPlayerNode = nil
    }
    
    private func configureAudioSession() {
      let audioSession = AVAudioSession.sharedInstance()
      do {
        // Set the audio session category to play and record, and default to speaker
        try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
        // Activate the audio session
        try audioSession.setActive(true)
      } catch {
        print("Failed to set up audio session: \(error.localizedDescription)")
      }
    }
  }
}

extension ViewModel.Home: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.audioPlayer = nil
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    self.audioPlayer = nil
    self.audioPlayerAlertMessage = IdentifiableMessages(message: "Audio player audio decoding error occurred")
  }

  func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
    print("Audio player was Interrupted")
  }

  func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
    print("Audio player interruption ended")
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
