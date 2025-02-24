//
//  RecordingControlsViewModel.swift
//  Zizh
//
//  Created by Marwan Tutunji on 17/02/2025.
//

import Combine
import Foundation

extension ViewModel {
  class RecordingControls: ObservableObject {
    @Published var state: RecordingState = .idle {
      didSet {
        handleStateChange()
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
        .sink(receiveValue: { [weak self] isRecording in
          self?.handleRecordingServiceStates(isRecording)
        })
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
      isRecording ? recordingService.stopRecording() : recordingService.startRecording()
    }
    
    var isRecording: Bool {
      switch state {
      case .start :
        return true
      default:
        return false
      }
    }
    
    private func addRecording(recordingURL: URL) async {
      guard let (id, timeInterval) = recordsRepository.fileManagement.extractRecordingInfo(from: recordingURL) else {
        print("Recorded file name is not in the correct format")
        return
      }
      let date = Date(timeIntervalSince1970: timeInterval)
      let duration = await self.recordingService.getRecordingDuration(url: recordingURL)
      let newRecording = AudioRecordData(id: id, duration: duration, name: date.ISO8601Format(), address: recordingURL)
      self.recordsRepository.addRecording(newRecording)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
          switch completion {
          case .failure(let error):
            self?.state = .finished(.failure(.repository(error)))
          case .finished:
            self?.state = .finished(.success(newRecording))
          }
        } receiveValue: { _ in }
        .store(in: &cancellables)
    }
    
    private func handleRecordingServiceStates(_ isRecording: Bool) {
      state = isRecording ? .start : .stop
    }
    
    private func handleStateChange() {
      isRecording ? startTimer() : stopTimer()
      recordingStateChangePublisher.send(state)
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

extension ViewModel.RecordingControls {
  enum RecordingState: Equatable {
    case idle
    case start
    case stop
    case finished(Result<any AudioRecord, RecordingError>)
    
    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
      switch (lhs, rhs) {
      case (.idle, .idle), (.start, .start), (.stop, .stop), (.finished, .finished):
        return true
      default:
        // TODO: Improve equatable for the .finished state
        return false
      }
    }
  }
  
  enum RecordingError: Error {
    case repository(RepositoryError)
  }
}
