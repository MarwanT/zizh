//
//  Records.swift
//  Zize
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Foundation

protocol Record {
  var id: UUID { get }
  var name: String { get }
  var path: URL { get }
  var createdAt: Date { get }
}

