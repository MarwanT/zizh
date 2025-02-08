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

@Suite(.serialized)
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
  
  @Test("Directories are created when FileManagement is initialised")
  func directoriesCreation() {
    // directories exist after initialisation
    #expect(fileManager.fileExists(atPath: sut.homeDirectoryURL.path()) == true)
    #expect(fileManager.fileExists(atPath: sut.persistedRecordingsDirectoryURL.path()) == true)
    #expect(fileManager.fileExists(atPath: sut.temporaryRecordingsDirectoryURL.path()) == true)
  }
  
  @Test("Generated new recording URL has the correct format")
  func generateValidNewRecordingURL() {
    let recordingURL = sut.generateNewRecordingURL()
    let extractedInfo = sut.extractRecordingInfo(from: recordingURL)
    #expect(extractedInfo != nil)
  }
  
  @Test("Extract recording info is successful from a valid URL")
  func extractRecordingInfo_ValidFormat() {
    let id = UUID()
    let timestamp = Date().timeIntervalSince1970
    let validURL = sut.persistedRecordingsDirectoryURL.appendingPathComponent("\(id.uuidString)_\(timestamp)_.m4a")
    
    let extractedInfo = sut.extractRecordingInfo(from: validURL)
    
    #expect(extractedInfo != nil)
    #expect(extractedInfo?.id == id)
    #expect(extractedInfo?.timestamp == timestamp)
  }
  
  @Test("Extract recording info fails from an invalid URL")
  func extractRecordingInfo_InvalidFormat() {
    let invalidURL = sut.persistedRecordingsDirectoryURL.appendingPathComponent("invalid_format.m4a")
    let extractedInfo = sut.extractRecordingInfo(from: invalidURL)
    #expect(extractedInfo == nil)
  }
  
  @Test("Delete an existing recording")
  func deleteRecording() {
    let testFileURL = sut.generateNewRecordingURL()
    let creationSuccess = fileManager.createFile(atPath: testFileURL.path(), contents: Data())
    #expect(creationSuccess == true)
    #expect(fileManager.fileExists(atPath: testFileURL.path()))
    
    sut.deleteRecording(at: testFileURL)
    
    #expect(!fileManager.fileExists(atPath: testFileURL.path()))
  }
  
  @Test("Move existing temporary recording to persisted location")
  func moveTemporaryRecordingToPersistedLocation_ExistingFile() {
    // given
    let success = fileManager.createFile(atPath: sut.temporaryRecordingURL.path(), contents: Data())
    #expect(success == true)
    // when
    let newAddress = sut.moveTemporaryRecordingToPersistedLocation(url: sut.temporaryRecordingURL)
    // then
    #expect(newAddress != nil)
  }
  
  @Test("Fail to move a non existing recording to persisted location")
  func moveTemporaryRecordingToPersistedLocation_FileDoesNotExist() {
    // when
    let newAddress = sut.moveTemporaryRecordingToPersistedLocation(url: sut.temporaryRecordingURL)
    // then
    #expect(newAddress == nil)
  }
  
  @Test("Removes all content of the Home directory")
  func cleanUpRemovesAllDirectoriesAndFiles() throws {
    try sut.cleanUp()
    #expect(fileManager.fileExists(atPath: sut.homeDirectoryURL.path()) == false)
  }
}
