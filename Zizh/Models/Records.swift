//
//  Records.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation
import SwiftData

@Model
class Recording: Identifiable, Equatable {
  var createdAt: Date
  var duration: TimeInterval
  var id: UUID
  var name: String
  var address: URL
  
  init(id: UUID = UUID(), duration: TimeInterval, name: String, address: URL, createdAt: Date = Date()) {
    self.id = id
    self.duration = duration
    self.name = name
    self.address = address
    self.createdAt = createdAt
  }
}

typealias AudioRecording = Recording
