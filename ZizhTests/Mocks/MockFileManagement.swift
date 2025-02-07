//
//  MockFileManagement.swift
//  Zizh
//
//  Created by Marwan Tutunji on 07/02/2025.
//

import Foundation
@testable import Zizh

final class MockFileManagement: DefaultFileManagement {
  var persistedRecords: [Recording] = []
  
  required init(homeDirectoryName: String = "ZizhTests", fileManager: FileManager = .default) {
    super.init(homeDirectoryName: homeDirectoryName, fileManager: fileManager)
  }
}
