//
//  Records.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation

struct Recording: Identifiable, Equatable {
  let createdAt: Date
  let duration: TimeInterval
  let id: UUID
  let name: String
  let address: URL
  
  init(id: UUID = UUID(), duration: TimeInterval, name: String, address: URL) {
    self.id = id
    self.duration = duration
    self.name = name
    self.address = address
    self.createdAt = Date()
  }
}

typealias AudioRecording = Recording
