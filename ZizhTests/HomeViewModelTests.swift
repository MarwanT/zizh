//
//  HomeViewModelTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Combine
import Foundation
import Testing
@testable import Zizh

@Suite(.serialized)
final class HomeViewModelTests {
  var sut: ViewModel.Home!
  let mockRecordsRepository: MockRecordRepository
  let mockRecordingService: MockRecordingService
  let fileManagement: FileManagement
  var cancellables: Set<AnyCancellable> = []
  
  init() {
    fileManagement = MockFileManagement()
    mockRecordingService = MockRecordingService()
    mockRecordsRepository = MockRecordRepository()
    sut = ViewModel.Home(recordingService: mockRecordingService, recordsRepository: mockRecordsRepository)
  }
  
  deinit {
    sut = nil
  }
  
  
}
