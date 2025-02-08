//
//  PermissionsService.swift
//  Zizh
//
//  Created by Marwan Tutunji on 30/01/2025.
//

import AVFAudio
import Combine

protocol MicrophonePermissionProvider {
  func requestPermission(_ completion: @escaping (Bool) -> Void)
}

class AVAudioPermissionProvider: MicrophonePermissionProvider {
  func requestPermission(_ completion: @escaping (Bool) -> Void) {
    AVAudioApplication.requestRecordPermission(completionHandler: completion)
  }
}

class PermissionsService {
  private let microphonePermissionProvider: MicrophonePermissionProvider
  init (_ microphonePermissionProvider: MicrophonePermissionProvider = AVAudioPermissionProvider()) {
    self.microphonePermissionProvider = microphonePermissionProvider
  }
  
  func requestMicrophonePermission() -> AnyPublisher<Bool, Never> {
    return Future { promise in
      self.microphonePermissionProvider.requestPermission { granted in
        if granted {
          print("Microphone permission granted")
        } else {
          print("Microphone permission not granted")
        }
        promise(.success(granted))
      }
    }.eraseToAnyPublisher()
  }
}
