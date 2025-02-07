//
//  FileManagementTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 07/02/2025.
//

import Foundation
import Testing
@testable import Zizh

extension DefaultFileManagement {
  func cleanUp() throws {
    try fileManager.removeItem(at: homeDirectoryURL)
  }
}

final class FileManagementTests {
  let fileManager: FileManager
  let sut: DefaultFileManagement
  
  init() {
    fileManager = FileManager.default
    sut = DefaultFileManagement(homeDirectoryName: "ZizhTests", fileManager: fileManager)
  }
  
  deinit {
    try? sut.cleanUp()
  }
  
  @Test
  func directoriesCreation() {
    // directories exist after initialisation
    #expect(fileManager.fileExists(atPath: sut.homeDirectoryURL.path()))
    #expect(fileManager.fileExists(atPath: sut.persistedRecordingsDirectoryURL.path()))
    #expect(fileManager.fileExists(atPath: sut.temporaryRecordingsDirectoryURL.path()))
  }
  
  @Test
  func generateValidNewRecordingURL() {
    let recordingURL = sut.generateNewRecordingURL()
    let extractedInfo = sut.extractRecordingInfo(from: recordingURL)
    #expect(extractedInfo != nil)
  }
  
  @Test
  func extractRecordingInfo_ValidFormat() {
    let id = UUID()
    let timestamp = Date().timeIntervalSince1970
    let validURL = sut.persistedRecordingsDirectoryURL.appendingPathComponent("\(id.uuidString)_\(timestamp)_.m4a")
    
    let extractedInfo = sut.extractRecordingInfo(from: validURL)
    
    #expect(extractedInfo != nil)
    #expect(extractedInfo?.id == id)
    #expect(extractedInfo?.timestamp == timestamp)
  }
  
  @Test
  func extractRecordingInfo_InvalidFormat() {
    let invalidURL = sut.persistedRecordingsDirectoryURL.appendingPathComponent("invalid_format.m4a")
    let extractedInfo = sut.extractRecordingInfo(from: invalidURL)
    #expect(extractedInfo == nil)
  }
  
  @Test
  func deleteRecording() {
    let testFileURL = sut.generateNewRecordingURL()
    fileManager.createFile(atPath: testFileURL.path(), contents: nil, attributes: nil)
    
    #expect(fileManager.fileExists(atPath: testFileURL.path()))
    
    sut.deleteRecording(at: testFileURL)
    
    #expect(!fileManager.fileExists(atPath: testFileURL.path()))
  }
  
  @Test
  func moveTemporaryRecordingToPersistedLocation_SuccessfulForExistingFile() {
    // given
    let success = fileManager.createFile(atPath: sut.temporaryRecordingURL.path(), contents: Data())
    #expect(success == true)
    // when
    let newAddress = sut.moveTemporaryRecordingToPersistedLocation(url: sut.temporaryRecordingURL)
    // then
    #expect(newAddress != nil)
  }
  
  @Test
  func moveTemporaryRecordingToPersistedLocation_FailForNonExistingFile() {
    // when
    let newAddress = sut.moveTemporaryRecordingToPersistedLocation(url: sut.temporaryRecordingURL)
    // then
    #expect(newAddress == nil)
  }
  
  @Test
  func cleanUpRemovesAllDirectoriesAndFiles() {
    #expect(!fileManager.fileExists(atPath: sut.homeDirectoryURL.path()))
  }
}
