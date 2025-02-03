//
//  AudioRepository.swift
//  Zize
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation

struct AudioRecordsRepository: RecordsRepository {
  private var fileManager: FileManager
  init(fileManager: FileManager = FileManager.default) {
    self.fileManager = fileManager
  }
  
  var temporaryRecordingURL: URL {
    return fileManager.temporaryDirectory.appendingPathComponent("temp.m4a")
  }
  
  var persistedRecordingsURL: URL {
    let recordingsURL = fileManager
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("AudioRecordings", isDirectory: true)
    if !fileManager.fileExists(atPath: recordingsURL.path()) {
      do {
        try fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
      } catch {
        // TODO: Handle the directory creation error in a better way
        print("Error creating the recordings directory: \(error)")
      }
    }
    return recordingsURL
  }
  
  func fetchRecords() -> [Record] {
    return []
  }
  
  func generateNewRecordingURL() -> URL {
    let now = Date().ISO8601Format()
    return persistedRecordingsURL.appendingPathComponent("\(now).m4a")
  }
}
