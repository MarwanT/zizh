//
//  FileManagement.swift
//  Zizh
//
//  Created by Marwan Tutunji on 05/02/2025.
//

import Foundation

protocol FileManagement {
  var temporaryRecordingURL: URL { get }
  var persistedRecordingsURL: URL { get }
  func generateNewRecordingURL() -> URL
  func deleteRecording(at url: URL)
  func extractRecordingInfo(from url: URL) -> (id: UUID, timestamp: TimeInterval)?
}

extension FileManager: FileManagement {
  var temporaryRecordingURL: URL {
    return self.temporaryDirectory.appendingPathComponent("temp.m4a")
  }
  
  var persistedRecordingsURL: URL {
    let recordingsURL = self.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("AudioRecordings", isDirectory: true)
    if !self.fileExists(atPath: recordingsURL.path()) {
      do {
        try self.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
      } catch {
        // TODO: Handle the directory creation error in a better way
        print("Error creating the recordings directory: \(error)")
      }
    }
    return recordingsURL
  }
  
  func generateNewRecordingURL() -> URL {
    let now = Date()
    let id = UUID()
    return self.persistedRecordingsURL.appendingPathComponent(
      "\(id.uuidString)_\(now.timeIntervalSince1970)_.m4a")
  }
  
  func extractRecordingInfo(from url: URL) -> (id: UUID, timestamp: TimeInterval)? {
    let nameComponents = url.lastPathComponent.components(separatedBy: CharacterSet(charactersIn: "_") )
    guard let id = UUID(uuidString: nameComponents[0]), let timeInterval = TimeInterval(nameComponents[1]) else {
      print("Recorded file name is not in the correct format")
      return nil
    }
    return (id: id, timestamp: timeInterval)
  }
  
  func deleteRecording(at url: URL) {
    do {
      try self.removeItem(at: url)
    } catch {
      print("Error deleting recording at \(url): \(error)")
    }
  }
}
