//
//  MockData.swift
//  Zizh
//
//  Created by Marwan Tutunji on 04/02/2025.
//

import Foundation
@testable import Zizh

struct MockData {
  static func recordings(count: Int) -> [Recording] {
    var recordings: [Recording] = []
    for index in 0..<count {
      let recording = Recording(
        duration: 10 + Double(index),
        name: "Test Recording \(index)",
        address: URL(string: "https://example.com/audio\(index).m4a")!
      )
      recordings.append(recording)
    }
    return recordings
  }
}
