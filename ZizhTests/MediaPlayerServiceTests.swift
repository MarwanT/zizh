//
//  AudioPlayerService.swift
//  Zizh
//
//  Created by Marwan Tutunji on 13/02/2025.
//

import Foundation
import Testing
@testable import Zizh

final class MediaPlayerServiceTests {
  var sut: MediaPlayerService!
  
  init() {
    sut = AudioPlayerService()
  }
  
  @Test("Has the proper state on initialization",
        .tags(.playback))
  func initialState() async throws {
    let initialStatus = await sut.status.values.first()
    #expect(initialStatus == .stopped)
  }
  
  @Test("Plays a recorded audio file in normal mode",
        .tags(.playback, .normalMode))
  func playNormalMode() async throws {
    // Given
    let url = try MockData.audioRecordingURL()
    #expect(url != nil)
    
    // When
    let result = sut.play(url)
    let playStatus = await sut.status.values.first()
    
    // Then
    #expect(result == .success(true))
    #expect(playStatus == .playing)
    
    // Wait until audio finishes
    let finishStatus = await sut.status.values.dropFirst().first()
    #expect(finishStatus == .stopped)
  }
  
  @Test("Plays a recorded audio file in slow motion mode",
        .tags(.playback, .slowMotion))
  func playSlowMotionMode() async throws {
    // Given
    let url = try MockData.audioRecordingURL()
    #expect(url != nil)
    let mode = PlayMode.slowMotion(0.5)
    
    // When
    let result = sut.play(url, mode: mode)
    let playStatus = await sut.status.values.first()
    
    // Then
    #expect(result == .success(true))
    #expect(playStatus == .playing)
    
    // Wait until audio finishes
    let finishStatus = await sut.status.values.dropFirst().first()
    #expect(finishStatus == .stopped)
  }
  
  
  @Test("Detects a non existing recording URL when playing normally",
    .tags(.errorHandling))
  func invalidURLPlaybackForNormalMode() async {
    // Given
    let url = MockData.invalidURL()
    
    // When
    let result = sut.play(url)
    let playStatus = await sut.status.values.first()
    
    // Then
    #expect(result == .failure(.invalidMediaAddress))
    #expect(playStatus == .stopped)
  }
  
  @Test("Detects a non existing recording URL when playing in slow motion",
    .tags(.errorHandling))
  func invalidURLPlaybackForSlowMotionMode() async {
    // Given
    let url = MockData.invalidURL()
    let mode = PlayMode.slowMotion(0.5)
    
    // When
    let result = sut.play(url, mode: mode)
    let playStatus = await sut.status.values.first()
    
    // Then
    #expect(result == .failure(.invalidMediaAddress))
    #expect(playStatus == .stopped)
  }
  
  @Test("Stops the audio while playing normally",
    .tags(.lifecycle))
  func stopNormalPlayback() async throws {
    // Given
    let url = try MockData.audioRecordingURL()
    #expect(url != nil)
    let result = sut.play(url)
    let playStatus = await sut.status.values.first()
    #expect(result == .success(true))
    #expect(playStatus == .playing)
    
    // When
    try await Task.sleep(for: .seconds(2))
    sut.stop()
    
    // Then
    let finishStatus = await sut.status.values.first()
    #expect(finishStatus == .stopped)
  }
  
  @Test("Stops the audio while playing slow motion",
    .tags(.lifecycle))
  func stopSlowMotionPlayback() async throws {
    // Given
    let url = try MockData.audioRecordingURL()
    let mode = PlayMode.slowMotion(0.5)
    #expect(url != nil)
    let result = sut.play(url, mode: mode)
    let playStatus = await sut.status.values.first()
    #expect(result == .success(true))
    #expect(playStatus == .playing)
    
    // When
    try await Task.sleep(for: .seconds(4))
    sut.stop()
    
    // Then
    let finishStatus = await sut.status.values.first()
    #expect(finishStatus == .stopped)
  }
  
  @Test("Fails with a playback error when error is related to av audio player",
    .tags(.errorHandling))
  func normalAudioSessionFailure() async throws {
    // Given
    sut = MockAudioPlayerService()
    let url = MockData.invalidURL()
    #expect(url != nil)
    
    // When
    let result = sut.play(url)
    let playStatus = await sut.status.values.first()
    
    // Then
    #expect(result == .failure(.playbackFailed))
    #expect(playStatus == .stopped)
  }
  
  @Test("Fails with a playback error when error is related to slow motion engine",
    .tags(.errorHandling))
  func slowMotionAudioSessionFailure() async throws {
    // Given
    sut = MockAudioPlayerService()
    let mode = PlayMode.slowMotion(0.5)
    let url = MockData.invalidURL()
    #expect(url != nil)
    
    // When
    let result = sut.play(url, mode: mode)
    let playStatus = await sut.status.values.first()
    
    // Then
    #expect(result == .failure(.playbackFailed))
    #expect(playStatus == .stopped)
  }
}

class MockAudioPlayerService: AudioPlayerService {
  override func validateURL(_ url: URL) -> Bool {
    return true
  }
}

// MARK: - Test Configuration
extension Tag {
  @Tag static var playback: Tag
  @Tag static var normalMode: Tag
  @Tag static var slowMotion: Tag
  @Tag static var errorHandling: Tag
  @Tag static var lifecycle: Tag
}
