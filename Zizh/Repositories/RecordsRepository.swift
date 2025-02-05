//
//  RecordsRepository.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Combine
import Foundation

protocol RecordsRepository {
  var temporaryRecordingURL: URL { get }
  var persistedRecordingsURL: URL { get }
  func fetchRecords() -> AnyPublisher<[Recording], Never>
  func generateNewRecordingURL() -> URL
  func deleteRecording(_ recording: Recording) -> AnyPublisher<Void, RecordingError>
}
