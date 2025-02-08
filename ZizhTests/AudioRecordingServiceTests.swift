//
//  AudioRecordingServiceTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import Foundation
import Testing
@testable import Zizh

struct RecordingServiceTests {
  let sut: RecordingService!
  let mockFileManagment: DefaultFileManagement!
  let mockPermissionService: PermissionsService
  let fileManager: FileManager!
  let microphonePermissionProvider: MockMicrophonePermissionProvider!
  
  init() throws {
    fileManager = FileManager.default
    mockFileManagment = MockFileManagement(fileManager: fileManager)
    microphonePermissionProvider = MockMicrophonePermissionProvider()
    mockPermissionService = PermissionsService(microphonePermissionProvider)
    sut = try AudioRecordingService(fileManagement: mockFileManagment, permissionService: mockPermissionService)
    microphonePermissionProvider.permissionResult = true
  }
  
  @Test("Starts recording audio")
  func startRecording() async {
    sut.startRecording()
    let value = await sut.isRecordingPublisher.values.first()
    #expect(value == true)
  }
  
//  @Test("Fails to record audio if permission is not granted")
//  func startRecording_NoPermission() async {
//    microphonePermissionProvider.permissionResult = false
//    sut.startRecording()
//    let value = await sut.isRecordingPublisher.values.first()
//    #expect(value == false)
//  }
  
  @Test("Stops recording a started recording")
  func stopsRecordingBeforeStart() async throws {
    // given
    sut.startRecording()
    try await Task.sleep(for: .milliseconds(200))
    
    // when
    sut.stopRecording()
    try await Task.sleep(for: .milliseconds(200))
    
    // then
    let value = await sut.isRecordingPublisher.values.first()
    #expect(value == false)
  }
  
  @Test("Stops recording a stopped recording")
  func stopsRecordingAfterStop() async throws {
    sut.stopRecording()
    try await Task.sleep(for: .milliseconds(200))
    let value = await sut.isRecordingPublisher.values.first()
    #expect(value == false)
  }
  
  @Test("Propagates the proper permission to microphone when granted")
  func microphonePermissionGranted() async {
    microphonePermissionProvider.permissionResult = true
    let permission = await sut.requestPermission().values.first()
    #expect(permission == true)
  }
  
  @Test("Propagates the proper permission to microphone when denied")
  func microphonePermissionDenied() async {
    microphonePermissionProvider.permissionResult = false
    let permission = await sut.requestPermission().values.first()
    #expect(permission == false)
  }
}
