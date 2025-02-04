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
}
