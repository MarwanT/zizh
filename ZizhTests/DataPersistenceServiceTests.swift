//
//  DataPersistenceServiceTests.swift
//  Zizh
//
//  Created by Marwan Tutunji on 05/02/2025.
//

import Combine
import Foundation
import Testing
@testable import Zizh

@MainActor
final class SwiftDataServiceTests {
  let sut: SwiftDataService
  
  init() throws {
    sut = try SwiftDataService(types: [Recording.self], isStoredInMemoryOnly: true)
  }
  
  @Test("Adds a new Item Successfully")
  func addItemSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 1)
    // when
    try await sut.add(item: recordings[0]).values.first()
    try await Task.sleep(for: .milliseconds(500))
    // then
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    try await Task.sleep(for: .milliseconds(500))
    #expect(allItems?.count == 1)
    #expect(allItems?.first == recordings[0])
  }
  
  @Test("Removes an added Item Successfully")
  func removeExistingItem() async throws {
    // given
    let recordings = MockData.recordings(count: 2)
    for recording in recordings {
      try await sut.add(item: recording).values.first()
      try await Task.sleep(for: .milliseconds(500))
    }
    // when
    try await sut.remove(item: recordings[1]).values.first()
    try await Task.sleep(for: .milliseconds(500))
    // then
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    #expect(allItems?.count == 1)
    #expect(allItems?.first == recordings[0])
  }
  
  @Test("Fails to remove a non existing item")
  func removeNonExistingItem() async throws {
    // given
    let recordings = MockData.recordings(count: 2)
    try await sut.add(item: recordings[0]).values.first()
    // when
    try await sut.remove(item: recordings[1]).values.first()
    try await Task.sleep(for: .milliseconds(500))
    // then
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    #expect(allItems?.count == 1)
    #expect(allItems?.first == recordings[0])
  }
  
  @Test("Fetches all persisted Items Successfully")
  func fetchAllItemsSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 3)
    for recording in recordings {
      try await sut.add(item: recording).values.first()
      try await Task.sleep(for: .milliseconds(500))
    }
    // when
    let allItems = try await sut.fetchAll(Recording.self).values.first()
    try await Task.sleep(for: .milliseconds(500))
    // then
    #expect(allItems != nil)
    #expect(allItems?.count == 3)
    for item in allItems! {
      #expect(recordings.contains(item))
    }
  }
  
  @Test("Fetches a specific persisted Item by id Successfully")
  func fetchItemSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 3)
    let viewedRecording = recordings[2]
    for recording in recordings {
      try await sut.add(item: recording).values.first()
      try await Task.sleep(for: .milliseconds(500))
    }
    // when
    let viewedId: UUID = viewedRecording.id
    let predicate = #Predicate<Recording> { recording in
      return recording.id == viewedId
    }
    let allItems = try await sut.fetch(Recording.self, predicate: predicate, sortBy: []).values.first()
    try await Task.sleep(for: .milliseconds(500))
    // then
    #expect(allItems != nil)
    #expect(allItems?.count == 1)
    #expect(allItems?[0].id == viewedRecording.id)
  }
  
  @Test("Fetches multiple persisted Items for predicate Successfully")
  func fetchItemsSuccessfully() async throws {
    // given
    let recordings = MockData.recordings(count: 3)
    let viewedRecordingsIds = [recordings[0].id, recordings[2].id]
    for recording in recordings {
      try await sut.add(item: recording).values.first()
      try await Task.sleep(for: .milliseconds(500))
    }
    // when
    let predicate = #Predicate<Recording> { $0.id == viewedRecordingsIds[0] || $0.id == viewedRecordingsIds[1] }
    let allItems = try await sut.fetch(Recording.self, predicate: predicate, sortBy: []).values.first()
    try await Task.sleep(for: .milliseconds(500))
    // then
    #expect(allItems != nil)
    #expect(allItems?.count == 2)
    for item in allItems! {
      #expect(viewedRecordingsIds.contains(item.id))
    }
  }
}


