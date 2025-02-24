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
  
  @Test("Fetches recordings successfully from repository")
  func fetchRecordingsFromRepository() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    
    // When
    try await sut.syncRecordings().async()
    
    // Then
    #expect(sut.records.count == mockRecordsRepository.persistedRecords.count)
    #expect(sut.records as! [AudioRecordData] == mockRecordsRepository.persistedRecords as! [AudioRecordData])
  }
  
  @Test("Updates a recording name successfully")
  func savesAnEditedRecordingName() async throws {
    // Given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    try await sut.syncRecordings().async()
    let targettedIndex = 3
    // When
    let updatedName = "Birds Singing"
    await sut.updateRecording(mockRecordsRepository.persistedRecords[targettedIndex].id, name: updatedName)
    // Then
    #expect(mockRecordsRepository.persistedRecords[targettedIndex].name == updatedName)
  }
  
  @Test("Fetches recordings from the repository with 10 recordings")
  func fetchRecordingsFromRepository_ManyRecordings() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 10)
    
    // when
    try await sut.syncRecordings().async()
    
    // then
    let results = await sut.$records.values.first()!
    #expect(mockRecordsRepository.persistedRecords as! [AudioRecordData] == results as! [AudioRecordData])
  }
  
  @Test("Fetches recordings from the repository with 0 recordings")
  func fetchRecordingsFromRepository_NoRecordings() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 0)
    
    // when
    try await sut.syncRecordings().async()
    
    // then
    let results = await sut.$records.values.first()!
    #expect(mockRecordsRepository.persistedRecords as! [AudioRecordData] == results as! [AudioRecordData])
  }
  
  @Test("Deletes successfully a recording")
  func deleteRecordingSuccessfully() async throws {
    // given
    mockRecordsRepository.persistedRecords = MockData.recordingsData(count: 11)
    let deletedRecordingIndex = 1
    let deletedRecording = mockRecordsRepository.persistedRecords[deletedRecordingIndex]
    try await sut.syncRecordings().async()
    
    // when
    sut.deleteRecording(at: IndexSet([deletedRecordingIndex]))
    
    // then
    #expect(mockRecordsRepository.persistedRecords.count == 10)
    #expect(try! mockRecordsRepository.persistedRecords.contains(where: { $0.id == deletedRecording.id }) == false)
  }
}
