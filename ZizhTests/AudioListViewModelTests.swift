//
//  AudioListViewModelTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 22/02/2025.
//

import Foundation
import Testing
@testable import Zizh

final class AudioListViewModelTests {
  let mockRecordsRepository: MockRecordRepository
  let sut: ViewModel.AudioList
  
  init() {
    mockRecordsRepository = MockRecordRepository()
    sut = ViewModel.AudioList(recordsRepository: mockRecordsRepository)
  }
  
  @Test("Fetches recordings from the repository with 10 recordings")
  func fetchRecordingsFromRepository_ManyRecordings() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    
    // when
    try await sut.syncRecordings().async()
    
    // then
    let results = await sut.$records.values.first()!
    #expect(mockRecordsRepository.persistedRecords == results as! [AudioRecordData])
  }
  
  @Test("Fetches recordings from the repository with 0 recordings")
  func fetchRecordingsFromRepository_NoRecordings() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 0)
    
    // when
    try await sut.syncRecordings().async()
    
    // then
    let results = await sut.$records.values.first()!
    #expect(mockRecordsRepository.persistedRecords == results as! [AudioRecordData])
  }
  
  @Test("Maintains UI consistency during rapid updates")
  func rapidUpdateConsistency() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 500)
    
    // When
    await withThrowingTaskGroup(of: Void.self) { group in
      for _ in 0..<300 {
        group.addTask { [weak self] in
          try await self?.sut.syncRecordings().async()
        }
      }
    }
    
    // Then
    #expect(sut.records.count == 500) // No duplicates/corruption
  }
  
  @Test("Fails to sync recordings on repository error")
  func syncRecordingsFailure() async throws {
    // Given
    mockRecordsRepository.callBehavior = .fail(.repositoryDeallocated)
    
    // When/Then
    await #expect(throws: ViewModel.AudioList.AudioListError.self) {
      try await sut.syncRecordings().async()
    }
  }
  
  @Test("Updates a recording name successfully")
  func savesAnEditedRecordingName() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    try await sut.syncRecordings().async()
    let targettedIndex = 3
    
    // When
    let updatedName = "Birds Singing"
    try await sut.updateRecording(mockRecordsRepository.persistedRecords[targettedIndex].id, name: updatedName).async()
    
    // Then
    let targettedRecord = mockRecordsRepository.persistedRecords[targettedIndex]
    #expect(targettedRecord.name == updatedName)
    let sutRecord = sut.records.first(where: { $0.id == targettedRecord.id })
    #expect(sutRecord != nil)
    #expect(sutRecord!.name == updatedName)
  }
  
  @Test("Handles concurrent updates")
  func concurrentUpdates() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 100)
    try await sut.syncRecordings().async()
    
    // When
    await withThrowingTaskGroup(of: Void.self) { group in
      for i in 0..<56 {
        group.addTask { [weak self] in
          guard let self = self else { return }
          let record = self.mockRecordsRepository.persistedRecords[i]
          try await self.sut.updateRecording(record.id, name: "Updated \(i)").async()
        }
      }
    }
    
    // Then
    #expect(mockRecordsRepository.persistedRecords.filter { $0.name.starts(with: "Updated") }.count == 56)
  }
  
  @Test("Fails to update a recording when repository throws an error")
  func updateRecordingFailure() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    let targettedRecording = mockRecordsRepository.persistedRecords[3]
    try await sut.syncRecordings().async()
    mockRecordsRepository.callBehavior = .fail(.repositoryDeallocated)
    
    // When/Then
    await #expect(throws: ViewModel.AudioList.AudioListError.self) {
      try await sut.updateRecording(targettedRecording.id, name: "Updated Name").async()
    }
  }
  
  @Test("Fails to update a non existing recording")
  func updateNonExistingRecordingFailure() async throws {
    // Given
    let recordings = MockData.recordingsData(count: 10)
    mockRecordsRepository.persistedRecords = Array(recordings[0...8])
    let excludedRecording = recordings[9]
    try await sut.syncRecordings().async()
    
    // When/Then
    await #expect(throws: ViewModel.AudioList.AudioListError.self) {
      try await sut.updateRecording(excludedRecording.id, name: "Updated Name").async()
    }
  }
  
  @Test("Deletes successfully a recording")
  func deleteRecordingSuccessfully() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 11)
    let deletedRecordingIndex = 1
    let deletedRecording = mockRecordsRepository.persistedRecords[deletedRecordingIndex]
    try await sut.syncRecordings().async()
    
    // When
    sut.deleteRecording(at: IndexSet([deletedRecordingIndex]))
    
    // Then
    #expect(mockRecordsRepository.persistedRecords.count == 10)
    #expect(try! mockRecordsRepository.persistedRecords.contains(where: { $0.id == deletedRecording.id }) == false)
  }
  
  @Test("Shows error when deleting non-existent recording")
  func deleteNonExistentRecording() async {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 11)
    let invalidIndex = IndexSet([100])
    
    // When
    Task { @MainActor in
      try await Task.sleep(for: .seconds(1))
      sut.deleteRecording(at: invalidIndex)
    }
    
    // Then
    let alert = await sut.alertPublisher.values.first(where: { _ in true })
    #expect(alert != nil)
    #expect(alert!!.message.contains("Failed to delete unrecognized recording") == true)
  }
  
  @Test("Shows error when repository fails to delete a recording for repository is deallocated")
  func deleteRecordingFailsForRepoDeallocated() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    let deletedRecordingIndex = 1
    try await sut.syncRecordings().async()
    mockRecordsRepository.callBehavior = .fail(.repositoryDeallocated)
    
    // When
    sut.deleteRecording(at: IndexSet([deletedRecordingIndex]))
    
    // Then
    let alert = await sut.alertPublisher.values.first(where: { _ in true })
    #expect(alert != nil)
    #expect(alert!!.message.contains("deallocated") == true)
  }
  
  @Test("Shows error when repository fails to delete a recording")
  func deleteRecordingFails() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    let deletedRecordingIndex = 1
    try await sut.syncRecordings().async()
    mockRecordsRepository.callBehavior = .fail(.deletionFailed(RepositoryError.unknown(nil)))
    
    // When
    sut.deleteRecording(at: IndexSet([deletedRecordingIndex]))
    
    // Then
    let alert = await sut.alertPublisher.values.first(where: { _ in true })
    #expect(alert != nil)
    #expect(alert!!.message.contains("Failed to delete recording") == true)
    #expect(alert!!.message.contains("deallocated") == false)
  }
  
  @Test("Publishes tap events correctly")
  func recordingTapPublication() async {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    let testRecording = mockRecordsRepository.persistedRecords[0]
    try? await sut.syncRecordings().async()
    
    // When
    Task { @MainActor in
      try await Task.sleep(for: .seconds(1))
      sut.handleRecordingTap(testRecording)
    }
    
    // Then
    let result = await sut.tapRecordingPublisher.values.first()
    #expect(result != nil)
    #expect(result! == testRecording)
  }
  
  @Test("Finds recording by URL correctly")
  func urlResolution() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    let testRecording = mockRecordsRepository.persistedRecords[4]
    try await sut.syncRecordings().async()
    
    // When
    let found = sut.recordingFromURL(testRecording.address)
    
    // Then
    #expect(found?.id == testRecording.id)
  }
}
