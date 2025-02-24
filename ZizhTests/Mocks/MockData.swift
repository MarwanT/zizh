//
//  MockData.swift
//  Zizh
//
//  Created by Marwan Tutunji on 04/02/2025.
//

import Foundation
@testable import Zizh

class MockData: AnyObject {
  static func recordingsData(count: Int) -> [any AudioRecord] {
    var recordings: [any AudioRecord] = []
    for index in 0..<count {
      let recording = AudioRecordData(
        duration: 10 + Double(index),
        name: "Test Recording \(index)",
        address: URL(string: "https://example.com/audio\(index).m4a")!
      )
      recordings.append(recording)
    }
    return recordings
  }
  
  static func audioRecordingURL() throws -> URL {
    let bundle = Bundle(for: Self.self)
    guard let url = bundle.url(forResource: "short-recording", withExtension: "m4a") else {
      throw NSError(domain: "Could not load audio recording for testing purposes", code: 0, userInfo: nil)
    }
    return url
  }
  
  static func invalidURL() -> URL {
    return URL(string: "invalid-url")!
  }
}
