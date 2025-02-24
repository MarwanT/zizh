//
//  RecordingControlsViewModelTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 22/02/2025.
//

import Foundation
import Testing
@testable import Zizh

final class RecordingControlsViewModelTests {
  let sut: ViewModel.RecordingControls
  let mockRecordsRepository: MockRecordRepository
  let mockRecordingService: MockRecordingService
  
  init() {
    mockRecordingService = MockRecordingService()
    mockRecordsRepository = MockRecordRepository()
    sut = ViewModel.RecordingControls(recordingService: mockRecordingService, recordsRepository: mockRecordsRepository)
  }
  
  @Test("Starts recording when toggled the first time")
  func startsRecordingWhenToggledTheFirstTime() async throws {
    // given
    #expect(sut.state == .idle)
    
    // when
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(500))
    
    // then
    let state = await sut.$state.values.first()
    #expect(state == .start)
  }
  
  @Test("Stops recording when toggled twice")
  func stopsRecordingWhenToggledTwice() async throws {
    // given
    #expect(sut.state == .idle)
    
    // when
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(500))
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(500))
    
    // then
    let state = await sut.$state.values.first()
    #expect(state == .finished(.success(MockData.recordingsData(count: 1)[0])))
  }
  
  @Test("Adds a recording when recording finishes")
  func addsARecordingWhenRecordingFinishes() async throws {
    // given
    #expect(sut.state == .idle)
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(200))
    
    // when
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(200))
    
    // then
    let recordings = try await mockRecordsRepository.fetchRecords().values.first()
    #expect(recordings?.count == 1)
  }
  
  @Test("Adds two recordings when recording finishes")
  func addsTwoRecordingsWhenRecordingFinishesTwice() async throws {
    // given
    #expect(sut.state == .idle)
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(200))
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(200))
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(200))
    
    // when
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(200))
    
    // then
    let recordings = try await mockRecordsRepository.fetchRecords().values.first()
    #expect(recordings?.count == 2)
  }
}
