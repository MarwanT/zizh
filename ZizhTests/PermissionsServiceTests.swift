//
//  PermissionsServiceTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 03/02/2025.
//

import Testing
@testable import Zizh

class MockMicrophonePermissionProvider: MicrophonePermissionProvider {
  var permissionResult: Bool = false
  func requestPermission(_ completion: @escaping (Bool) -> Void) {
    completion(permissionResult)
  }
}

struct PermissionsServiceTests {
  let mockProvider: MockMicrophonePermissionProvider
  let sut: PermissionsService
  
  init() {
    mockProvider = MockMicrophonePermissionProvider()
    sut = PermissionsService(mockProvider)
  }
  
  @Test
  func requestMicrophonePermission_granted() async {
    // given
    mockProvider.permissionResult = true
    // when
    let granted = await self.sut.requestMicrophonePermission().values.first()
    // then
    #expect(granted == true)
  }
  
  @Test
  func requestMicrophonePermission_denied() async {
    mockProvider.permissionResult = false
    let granted = await self.sut.requestMicrophonePermission().values.first()
    #expect(granted == false)
  }
}
