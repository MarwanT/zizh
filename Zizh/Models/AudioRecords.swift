//
//  Records.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation
import SwiftData

protocol AudioRecord: Identifiable, Equatable {
  init(id: UUID, duration: TimeInterval, name: String, address: URL, createdAt: Date)
  var createdAt: Date { get set }
  var duration: TimeInterval { get set }
  var id: UUID { get set }
  var name: String { get set }
  var address: URL { get set }
}

extension AudioRecord {
  static func entityFrom<T: AudioRecord>(_ entity: any AudioRecord) -> T {
    return T.init(
      id: entity.id,
      duration: entity.duration,
      name: entity.name,
      address: entity.address,
      createdAt: entity.createdAt
    )
  }
}

@Model
class Recording: AudioRecord {
  var createdAt: Date
  var duration: TimeInterval
  var id: UUID
  var name: String
  var address: URL
  
  required init(id: UUID = UUID(), duration: TimeInterval, name: String, address: URL, createdAt: Date = Date()) {
    self.id = id
    self.duration = duration
    self.name = name
    self.address = address
    self.createdAt = createdAt
  }
}

struct AudioRecordData: AudioRecord {
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
