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
  
  func deleteRecording(at url: URL) {
    do {
      try self.removeItem(at: url)
    } catch {
      print("Error deleting recording at \(url): \(error)")
    }
  }
}
