//
//  AudioRecordingServiceTests.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Testing
@testable import Zize

struct RecordingServiceTests {
  var sut: RecordingService!
  
  init() {
    sut = AudioRecordingService()
  }
  
  @Test
  func startRecording() async {
    sut.startRecording()
    let value = await sut.isRecordingPublisher.values.first()
    #expect(value == true)
  }
  
  @Test
  func stopsRecording() async {
    sut.stopRecording()
    let value = await sut.isRecordingPublisher.values.first()
    #expect(value == false)
  }
}
