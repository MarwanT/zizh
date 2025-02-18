//
//  RecordingViewModel.swift
//  Zizh
//
//  Created by Marwan Tutunji on 17/02/2025.
//

import Combine
import Foundation

extension ViewModel {
  class Recording: ObservableObject {
    @Published var isRecording: Bool = false {
      didSet {
        handleIsRecordingFlagChanges()
      }
    }
    @Published var elapsedTimeString: String = "00:00"
    let recordingStateChangePublisher = PassthroughSubject<RecordingState, Never>()
    
    private var recordingStartDate: Date?
    private var timer: AnyCancellable?
    
    private var recordingService: RecordingService
    private var recordsRepository: any RecordsRepository
    private var cancellables: Set<AnyCancellable> = []
    
    init(recordingService: RecordingService? = nil, recordsRepository: (any RecordsRepository)? = nil) {
      self.recordsRepository = try! recordsRepository ?? AudioRecordsRepository()
      self.recordingService = try! recordingService ?? AudioRecordingService()
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
    }
    
    deinit {
      stopTimer()
    }
    
    func requestPermission() -> AnyPublisher<Bool, Never> {
      return recordingService.requestPermission()
    }
    
    func toggleRecording() {
      if (isRecording) {
        recordingService.stopRecording()
      } else {
        recordingService.startRecording()
      }
    }
    
    private func addRecording(recordingURL: URL) async {
      guard let (id, timeInterval) = recordsRepository.fileManagement.extractRecordingInfo(from: recordingURL) else {
        print("Recorded file name is not in the correct format")
        return
      }
      let date = Date(timeIntervalSince1970: timeInterval)
      let duration = await self.recordingService.getRecordingDuration(url: recordingURL)
      let newRecording = RecordingData(id: id, duration: duration, name: date.ISO8601Format(), address: recordingURL)
      self.recordsRepository.addRecording(newRecording)
        .receive(on: DispatchQueue.main)
        .sink { _ in
          // TODO: print and hadle errors here
        } receiveValue: { [weak self] in
          guard let self = self else { return }
          recordingStateChangePublisher.send(.finishedRecording(newRecording))
        }
        .store(in: &cancellables)
    }
    
    private func handleIsRecordingFlagChanges() {
      if isRecording {
        startTimer()
        recordingStateChangePublisher.send(.beginRecording)
      } else {
        stopTimer()
        // The recordingStateChangePublisher is triggered after adding the recording
      }
    }
    
    private func startTimer() {
      recordingStartDate = Date()
      timer?.cancel()  // Cancel previous timer if any
      
      // Create new timer subscription
      timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
          guard let self = self, let startDate = self.recordingStartDate else { return }
          let elapsed = Date().timeIntervalSince(startDate)
          self.updateTimeString(time: elapsed)
        }
    }
    
    private func stopTimer() {
      timer?.cancel()
      timer = nil
      elapsedTimeString = "00:00"
    }
    
    private func updateTimeString(time: TimeInterval) {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.minute, .second]
      formatter.unitsStyle = .positional
      formatter.zeroFormattingBehavior = .pad
      elapsedTimeString = formatter.string(from: time) ?? "00:00"
    }
  }
}

extension ViewModel.Recording {
  enum RecordingState {
    case beginRecording
    case finishedRecording(any RecordDataEntity)
  }
}
