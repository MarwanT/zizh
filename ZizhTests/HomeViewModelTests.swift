//
//  HomeViewModelTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Combine
import Foundation
import Testing
@testable import Zizh

@Suite(.serialized)
final class HomeViewModelTests {
  var sut: ViewModel.Home!
  let mockRecordsRepository: MockRecordRepository
  let mockRecordingService: MockRecordingService
  let fileManagement: FileManagement
  var cancellables: Set<AnyCancellable> = []
  
  init() {
    fileManagement = MockFileManagement()
    mockRecordingService = MockRecordingService()
    mockRecordsRepository = MockRecordRepository()
    sut = ViewModel.Home(recordingService: mockRecordingService, recordsRepository: mockRecordsRepository)
  }
  
  deinit {
    sut = nil
  }
  
  @Test("Starts recording when toggled the first time")
  func startsRecordingWhenToggledTheFirstTime() async throws {
    // given
    #expect(sut.isRecording == false)
    
    // when
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(500))
    
    // then
    let isRecording = await sut.$isRecording.values.first()
    #expect(isRecording == true)
  }
  
  @Test("Stops recording when toggled twice")
  func stopsRecordingWhenToggledTwice() async throws {
    // given
    #expect(sut.isRecording == false)
    
    // when
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(500))
    sut.toggleRecording()
    try await Task.sleep(for: .milliseconds(500))
    
    // then
    let isRecording = await sut.$isRecording.values.first()
    #expect(isRecording == false)
  }
  
  @Test("Adds a recording when recording finishes")
  func addsARecordingWhenRecordingFinishes() async throws {
    // given
    #expect(sut.isRecording == false)
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
    #expect(sut.isRecording == false)
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
  
  @Test("Fetches recordings from the repository with 10 recordings")
  func fetchRecordingsFromRepository_ManyRecordings() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordings(count: 10) 
    
    // when
    sut.syncRecordings()
    try await Task.sleep(for: .milliseconds(200))
    
    // then
    let results = await sut.$recordings.values.first()
    #expect(mockRecordsRepository.persistedRecords == results)
  }
  
  @Test("Fetches recordings from the repository with 0 recordings")
  func fetchRecordingsFromRepository_NoRecordings() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordings(count: 0) 
    
    // when
    sut.syncRecordings()
    try await Task.sleep(for: .milliseconds(200))
    
    // then
    let results = await sut.$recordings.values.first()!.map { $0 }
    #expect(mockRecordsRepository.persistedRecords == results)
  }
  
  @Test
  func deleteRecordingSuccessfully() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordings(count: 11)
    let deletedRecordingIndex = 1
    let deletedRecording = mockRecordsRepository.persistedRecords[deletedRecordingIndex]
    sut.syncRecordings()
    try await Task.sleep(for: .milliseconds(200))
    
    // when
    sut.deleteRecording(at: IndexSet([deletedRecordingIndex]))
    
    // then
    #expect(mockRecordsRepository.persistedRecords.count == 10)
    #expect(!mockRecordsRepository.persistedRecords.contains(deletedRecording))
  }
}
