//
//  AudioRepositoryTests.swift
//  Zize
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation
import Testing
@testable import Zize

struct AudioRecordsRepositoryTests {
  let sut: AudioRecordsRepository!
  let mockFileManager: FileManager!
  
  init() {
    mockFileManager = FileManager()
    sut = AudioRecordsRepository(fileManager: mockFileManager)
    do {
      try mockFileManager.removeItem(at: sut.persistedRecordingsURL)
    } catch {
      print("Failed to empty the recordings directory when performing tests: \(error)")
    }
  }
  
  @Test
  func getTemporaryAudioFileURL() {
    // when
    let temporaryFileURL = sut.temporaryRecordingURL
    // then
    #expect(temporaryFileURL.lastPathComponent == "temp.m4a")
  }
  
  @Test
  func persistedRecordingsURL_CreatesDirectoryIfNotExists() {
    // when
    let recordingsDirectory = sut.persistedRecordingsURL
    // then
    #expect(recordingsDirectory.hasDirectoryPath == true)
    #expect(recordingsDirectory.lastPathComponent == "AudioRecordings")
    #expect(mockFileManager.fileExists(atPath: recordingsDirectory.path) == true)
  }
  
  @Test
  func generateANewRecordingURLSuccessfully() {
    // when
    let newRecordingURL = sut.generateNewRecordingURL()
    // then
    #expect(newRecordingURL.isFileURL == true)
    #expect(newRecordingURL.lastPathComponent.hasSuffix(".m4a"))
  }
  
  
  
  @Test
  func deleteRecording() async throws {
    // given
    let recordName = "testingRecord.m4a"
    let recording = Recording(duration: 10, name: recordName, address: sut.persistedRecordingsURL.appendingPathComponent(recordName))
    let created = mockFileManager.createFile(
      atPath: recording.address.path(),
      contents: Data())
    #expect(created == true)
    // when
    try await sut.deleteRecording(recording).values.first()
    // then
    let filestillExists = mockFileManager.fileExists(atPath: recording.address.path())
    #expect(filestillExists == false)
  }
}
