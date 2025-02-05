//
//  DataPersistenceServiceTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 05/02/2025.
//

import Combine
import Testing
@testable import Zizh

@MainActor
final class SwiftDataServiceTests {
  let sut: SwiftDataService
  
  init() throws {
    sut = try SwiftDataService(types: [Recording.self], isStoredInMemoryOnly: true)
  }
  
  @Test
  func addItemSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 1)
    // when
    sut.add(item: recordings[0])
    // then
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    try await Task.sleep(nanoseconds: 500_000_000)
    #expect(allItems?.count == 1)
    #expect(allItems?.first == recordings[0])
  }
  
  @Test
  func removeItemSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 2)
    for recording in recordings {
      sut.add(item: recording)
    }
    // when
    sut.remove(item: recordings[1])
    try await Task.sleep(nanoseconds: 500_000_000)
    // then
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    #expect(allItems?.count == 1)
    #expect(allItems?.first == recordings[0])
  }
  
  @Test
  func fetchAllItemsSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 3)
    for recording in recordings {
      sut.add(item: recording)
    }
    // when
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    try await Task.sleep(nanoseconds: 500_000_000)
    // then
    #expect(allItems != nil)
    #expect(allItems?.count == 3)
    for item in allItems! {
      #expect(recordings.contains(item))
    }
  }
}


