//
//  HomeViewModelTests.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Combine
import Foundation
import Testing
@testable import Zize



final class HomeViewModelTests {
  let mockRecordsRepository: MockRecordRepository
  let mockRecordingService: MockRecordingService
  let sut: HomeViewModel
  var cancellables: Set<AnyCancellable> = []
  
  init() {
    mockRecordsRepository = MockRecordRepository()
    mockRecordingService = MockRecordingService(recordsRepository: mockRecordsRepository)
    sut = HomeViewModel(recordingService: mockRecordingService, recordsRepository: mockRecordsRepository)
  }
  
  @Test
  func toggleRecordingStartsAndStopsRecording() async throws {
    // given
    var values: [Bool] = []
    #expect(sut.isRecording == false)
    // when => then
    sut.toggleRecording()
    try await Task.sleep(nanoseconds: 500_000_000)
    for await value in sut.$isRecording.values.prefix(1) {
      values.append(value)
    }
    sut.toggleRecording()
    try await Task.sleep(nanoseconds: 500_000_000)
    for await value in sut.$isRecording.values.prefix(1) {
      values.append(value)
    }
    #expect(values == [true, false])
  }
  
  @Test
  func fetchRecordingsFromRepository_ManyRecordings() async {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordings(count: 10) 
    // when
    sut.syncRecordings()
    let results = await sut.$recordings.values.first()!.map { $0 }
    // then
    #expect(mockRecordsRepository.persistedRecords == results)
  }
  
  @Test
  func fetchRecordingsFromRepository_NoRecordings() async {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordings(count: 0) 
    // when
    sut.syncRecordings()
    let results = await sut.$recordings.values.first()!.map { $0 }
    // then
    #expect(mockRecordsRepository.persistedRecords == results)
  }
  
  @Test
  func deleteRecordingSuccessfully() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordings(count: 11)
    let deletedRecordingIndex = 1
    let deletedRecording = mockRecordsRepository.persistedRecords[deletedRecordingIndex]
    sut.syncRecordings()
    try await Task.sleep(nanoseconds: 500_000_000)
    // when
    sut.deleteRecording(at: IndexSet([deletedRecordingIndex]))
    // then
    #expect(mockRecordsRepository.persistedRecords.count == 10)
    #expect(!mockRecordsRepository.persistedRecords.contains(deletedRecording))
  }
}
