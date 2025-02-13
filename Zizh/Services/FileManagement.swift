//
//  FileManagement.swift
//  Zizh
//
//  Created by Marwan Tutunji on 05/02/2025.
//

import Foundation

protocol FileManagement {
  init(homeDirectoryName: String, fileManager: FileManager)
  var persistedRecordingsDirectoryURL: URL { get }
  var temporaryRecordingsDirectoryURL: URL { get }
  var temporaryRecordingURL: URL { get }
  func deleteRecording(at url: URL)
  func extractRecordingInfo(from url: URL) -> (id: UUID, timestamp: TimeInterval)?
  func generateNewRecordingURL() -> URL
  func moveTemporaryRecordingToPersistedLocation(url: URL) -> URL?
  func isRelativeURL(_ url: URL) -> Bool
  func makeRelativeURL(_ url: URL) throws -> URL
  func makeAbsoluteURL(_ url: URL) -> URL
}

enum FileManagementError: Error {
  case urlFormatUnrecgonized
  case invalidFileURL
}

class DefaultFileManagement: FileManagement {
  let fileManager: FileManager
  let homeDirectoryURL: URL
  let persistedRecordingsDirectoryURL: URL
  let temporaryRecordingsDirectoryURL: URL
  let temporaryRecordingURL: URL
  
  required init(homeDirectoryName: String = "zizh", fileManager: FileManager = FileManager.default) {
    self.fileManager = fileManager
    homeDirectoryURL = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask)[0].appendingPathComponent(homeDirectoryName, isDirectory: true)
    persistedRecordingsDirectoryURL = homeDirectoryURL.appendingPathComponent("recordings", isDirectory: true)
    temporaryRecordingsDirectoryURL = homeDirectoryURL.appendingPathComponent("temp", isDirectory: true)
    temporaryRecordingURL = temporaryRecordingsDirectoryURL.appendingPathComponent("temp.m4a")
    createDirectories(directories: [homeDirectoryURL, persistedRecordingsDirectoryURL, temporaryRecordingsDirectoryURL])
  }
  
  func generateNewRecordingURL() -> URL {
    let now = Date()
    let id = UUID()
    return persistedRecordingsDirectoryURL.appendingPathComponent(
      "\(id.uuidString)_\(now.timeIntervalSince1970)_.m4a")
  }
  
  func extractRecordingInfo(from url: URL) -> (id: UUID, timestamp: TimeInterval)? {
    let nameComponents = url.lastPathComponent.components(separatedBy: CharacterSet(charactersIn: "_") )
    guard nameComponents.count > 2,
            let id = UUID(uuidString: nameComponents[0]),
            let timeInterval = TimeInterval(nameComponents[1]) else {
      print("Recorded file name is not in the correct format")
      return nil
    }
    return (id: id, timestamp: timeInterval)
  }
  
  func deleteRecording(at url: URL) {
    do {
      try fileManager.removeItem(at: url)
    } catch {
      print("Error deleting recording at \(url): \(error)")
    }
  }
  
  func moveTemporaryRecordingToPersistedLocation(url: URL) -> URL? {
    let durableFileURL = generateNewRecordingURL()
    do {
      try fileManager.moveItem(at: url, to: durableFileURL)
      return durableFileURL
    } catch {
      print("Error moving audio file: \(error)")
      return nil
    }
  }
  
  func isRelativeURL(_ url: URL) -> Bool {
    let containsTheDocumentPath = url.pathComponents.contains(where: { $0 == "Documents"})
    return !containsTheDocumentPath
  }
  
  func makeRelativeURL(_ url: URL) throws -> URL {
    guard !isRelativeURL(url),
          let indexOfDocumentsPath = url.pathComponents.firstIndex(of: "Documents") else { return url }
    let relativePathComponents = url.pathComponents[(indexOfDocumentsPath + 1)...]
    guard let relativeURL = URL(string: relativePathComponents.joined(separator: "/")) else {
      throw FileManagementError.invalidFileURL
    }
    return relativeURL
  }
  
  func makeAbsoluteURL(_ url: URL) -> URL {
    guard isRelativeURL(url) else { return url }
    return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.path())
  }
  
  private func createDirectories(directories: [URL]) {
    for directory in directories {
      guard !fileManager.fileExists(atPath: directory.path()) else { continue }
      do {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        print("Directory '\(directory.lastPathComponent)' created successfully.")
      } catch {
        print("Error creating directory '\(directory.lastPathComponent)': \(error)")
      }
    }
  }
}
  
