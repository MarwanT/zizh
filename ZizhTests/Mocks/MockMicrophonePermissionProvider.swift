//
//  MockMicrophonePermissionProvider.swift
//  Zizh
//
//  Created by Marwan Tutunji on 07/02/2025.
//

@testable import Zizh

final class MockMicrophonePermissionProvider: MicrophonePermissionProvider {
  var permissionResult: Bool = false
  func requestPermission(_ completion: @escaping (Bool) -> Void) {
    completion(permissionResult)
  }
}
