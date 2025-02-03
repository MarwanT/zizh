//
//  RecordsRepository.swift
//  Zize
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation

protocol RecordsRepository {
  var temporaryRecordingURL: URL { get }
  var persistedRecordingsURL: URL { get }
  func fetchRecords() -> [Record]
  func generateNewRecordingURL() -> URL
}
