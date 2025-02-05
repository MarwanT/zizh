//
//  AudioRepository.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Combine
import Foundation

class AudioRecordsRepository: RecordsRepository {  
  private var fileManager: FileManager
  
  private var cancellables: Set<AnyCancellable> = []
  
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
  
  func fetchRecords() -> AnyPublisher<[Recording], Never> {
    var recordings: [Recording]
    do {
      let filesURLs = try fileManager.contentsOfDirectory(atPath: persistedRecordingsURL.path())
      recordings = filesURLs.map { recordName in
        let audioRecording = AudioRecording(duration: 0, name: recordName, address: persistedRecordingsURL.appendingPathComponent(recordName))
        return audioRecording
      }.sorted { $0.name > $1.name }
    } catch {
      recordings = []
      print("An error occured while fetching recordings: \(error)")
    }
    return Just(recordings).eraseToAnyPublisher()
  }
  
  func generateNewRecordingURL() -> URL {
    let now = Date().ISO8601Format()
    return persistedRecordingsURL.appendingPathComponent("\(now).m4a")
  }
  
  func deleteRecording(_ recording: Recording) -> AnyPublisher<Void, RecordingError> {
    return Future<Void, RecordingError> { [weak self] promise in
      guard let self = self else {
        promise(.failure(.repositoryDeallocated))
        return
      }
      do {
        try self.fileManager.removeItem(at: recording.address)
        promise(.success(()))
      } catch {
        print("An Error occured while deleting recording: \(error)")
        promise(.failure(.deletionFailed(error)))
      }
    }.eraseToAnyPublisher()
  }
}

enum RecordingError: Error {
    case repositoryDeallocated
    case deletionFailed(Error)
}
