//
//  ViewModelTests.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Combine
import Testing
@testable import Zize

final class ViewModelTests {
  let sut: ViewModel!
  
  init() {
    let mockRecordingService = MockRecordingService()
    sut = ViewModel(recordingService: mockRecordingService)
  }
  
  @Test
  func toggleRecordingStartsAndStopsRecording() async throws {
    // given
    var values: [Bool] = []
    #expect(sut.isRecording == false)
    // when => then
    sut.toggleRecording()
    try await Task.sleep(nanoseconds: 500_000_000)
    for await value in sut.$isRecording.values.prefix(1) {
      values.append(value)
    }
    sut.toggleRecording()
    try await Task.sleep(nanoseconds: 500_000_000)
    for await value in sut.$isRecording.values.prefix(1) {
      values.append(value)
    }
    #expect(values == [true, false])
  }
}
