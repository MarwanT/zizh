//
//  AudioRepositoryTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation
import Testing
@testable import Zizh

@Suite(.serialized)
final class AudioRecordsRepositoryTests {
  var sut: RecordsRepository!
  let mockFileManagment: DefaultFileManagement!
  let fileManager: FileManager!
  let dataPersistenceService: DataPersistenceService!
  
  init() throws {
    fileManager = FileManager.default
    mockFileManagment = MockFileManagement(fileManager: fileManager)
    dataPersistenceService = try SwiftDataService(isStoredInMemoryOnly: true)
    sut = try AudioRecordsRepository(dataPersistence: dataPersistenceService, fileManagement: mockFileManagment)
  }
  
  deinit {
    try? mockFileManagment.cleanUp()
    sut = nil
  }
  
  @Test("Adds a new recording")
  func addNewRecording() async throws {
    // given
    let recordingURL = mockFileManagment.generateNewRecordingURL()
    let (id, timeInterval) = mockFileManagment.extractRecordingInfo(from: recordingURL)!
    let recording = Recording(id: id, duration: timeInterval, name: Date(timeIntervalSince1970: timeInterval).ISO8601Format(), address: recordingURL)
    let created = fileManager.createFile(atPath: recordingURL.path(), contents: Data())
    #expect(created == true)
    
    // when
    try await sut.addRecording(recording).values.first()
    
    // then
    let recordingId = recording.id
    let predicate = #Predicate<Recording> { $0.id == recordingId }
    let persistedRecordingData = try await dataPersistenceService.fetch(Recording.self, predicate: predicate, sortBy: []).values.first()
    #expect(persistedRecordingData != [])
    #expect(persistedRecordingData?.count == 1)
    #expect(persistedRecordingData?[0] == recording)
    #expect(mockFileManagment.isRelativeURL(persistedRecordingData![0].address) == true)
  }
  
  @Test("Delets an existing recording")
  func deleteExistingRecording() async throws {
    // given
    let recordingURL = mockFileManagment.generateNewRecordingURL()
    let (id, timeInterval) = mockFileManagment.extractRecordingInfo(from: recordingURL)!
    let recording = Recording(id: id, duration: timeInterval, name: Date(timeIntervalSince1970: timeInterval).ISO8601Format(), address: recordingURL)
    let created = fileManager.createFile(atPath: recordingURL.path(), contents: Data())
    #expect(created == true)
    
    // when
    try await sut.deleteRecording(recording).values.first()
    
    // then
    let recordingId = recording.id
    let predicate = #Predicate<Recording> { $0.id == recordingId }
    let persistedRecordingData = try await dataPersistenceService.fetch(Recording.self, predicate: predicate, sortBy: []).values.first()
    #expect(persistedRecordingData == [])
    let fileExists = fileManager.fileExists(atPath: recordingURL.path())
    #expect(fileExists == false)
  }
  
  @Test("Fetches all records added")
  func fetchAllRecords() async throws {
    // given
    var recordings: [Recording] = []
    for _ in 0..<5 {
      let recordingURL = mockFileManagment.generateNewRecordingURL()
      let (id, timeInterval) = mockFileManagment.extractRecordingInfo(from: recordingURL)!
      let recording = Recording(
        id: id,
        duration: timeInterval,
        name: Date(timeIntervalSince1970: timeInterval).ISO8601Format(),
        address: recordingURL)
      let created = fileManager.createFile(atPath: recordingURL.path(), contents: Data())
      #expect(created == true)
      try await dataPersistenceService.add(item: recording).values.first()
      recordings.append(recording)
    }
    
    // when
    let persistedRecordingsData = try await dataPersistenceService.fetchAll(Recording.self).values.first()
    
    // then
    #expect(persistedRecordingsData != nil)
    #expect(persistedRecordingsData?.count == 5)
    for persistedRecording in persistedRecordingsData! {
      #expect(recordings.contains(where: { $0.id == persistedRecording.id }))
      let fileExists = fileManager.fileExists(atPath: persistedRecording.address.path())
      #expect(fileExists == true)
      #expect(mockFileManagment.isRelativeURL(persistedRecording.address) == true)
    }
  }
  
  @Test("Fetches all remaining records")
  func fetchAllRemainingRecords() async throws {
    // given
    var recordings: [Recording] = []
    for _ in 0..<5 {
      let recordingURL = mockFileManagment.generateNewRecordingURL()
      let (id, timeInterval) = mockFileManagment.extractRecordingInfo(from: recordingURL)!
      let recording = Recording(id: id, duration: timeInterval, name: Date(timeIntervalSince1970: timeInterval).ISO8601Format(), address: recordingURL)
      let created = fileManager.createFile(atPath: recordingURL.path(), contents: Data())
      #expect(created == true)
      try await dataPersistenceService.add(item: recording).values.first()
      recordings.append(recording)
    }
    
    // when
    let deletedRecordings = [recordings[1], recordings[3]]
    for recording in deletedRecordings {
      try await sut.deleteRecording(recording).values.first()
    }
    let persistedRecordingsData = try await dataPersistenceService.fetchAll(Recording.self).values.first()
    
    // then
    #expect(persistedRecordingsData != nil)
    #expect(persistedRecordingsData?.count == 3)
    for persistedRecording in persistedRecordingsData! {
      #expect(!deletedRecordings.contains(where: { $0.id == persistedRecording.id }))
      let fileExists = fileManager.fileExists(atPath: persistedRecording.address.path())
      #expect(fileExists == true)
      #expect(mockFileManagment.isRelativeURL(persistedRecording.address) == true)
    }
  }
}
