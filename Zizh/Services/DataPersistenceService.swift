//
//  DataPersistenceService.swift
//  Zizh
//
//  Created by Marwan Tutunji on 05/02/2025.
//

import Combine
import Foundation
import SwiftData

typealias Persistable = SwiftData.PersistentModel
typealias Sorting<Persistable> = SortDescriptor<Persistable>

enum DataPersistenceError: Error {
  case failedToFetchData(Error)
  case serviceDeallocated
}

protocol DataPersistenceService {
  @MainActor func add(item: any Persistable) -> AnyPublisher<Void, DataPersistenceError>
  @MainActor func remove(item: any Persistable) -> AnyPublisher<Void, DataPersistenceError>
  @MainActor func fetchAll<T: Persistable>(_ type: T.Type) -> AnyPublisher<[T], DataPersistenceError>
  @MainActor func fetchAll<T: Persistable>(_ type: T.Type, sortBy: [Sorting<T>]) -> AnyPublisher<[T], DataPersistenceError>
}

class SwiftDataService: DataPersistenceService {
  let modelContainer: ModelContainer
  
  init(types: [any Persistable.Type] = [Recording.self], isStoredInMemoryOnly: Bool = false) throws {
    let schema = Schema(types)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
    modelContainer = try ModelContainer(for: schema, configurations: configuration)
  }
  
  func add(item: any Persistable) -> AnyPublisher<Void, DataPersistenceError> {
    return Future<Void, DataPersistenceError> { [unowned self] promise in
      self.modelContainer.mainContext.insert(item)
      self.save()
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func remove(item: any Persistable) -> AnyPublisher<Void, DataPersistenceError> {
    return Future<Void, DataPersistenceError> { [unowned self] promise in
      self.modelContainer.mainContext.delete(item)
      self.save()
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
  
  func fetchAll<T>(_ type: T.Type) -> AnyPublisher<[T], DataPersistenceError> where T : PersistentModel {
    return fetchAll(type, sortBy: [])
  }
  
  func fetchAll<T>(_ type: T.Type, sortBy: [Sorting<T>] = []) -> AnyPublisher<[T], DataPersistenceError> where T : PersistentModel {
    return Future<[T], DataPersistenceError> { [weak self] promise in
      let descriptor = FetchDescriptor<T>(sortBy: sortBy)
      do {
        guard let self = self else {
          promise(.failure(.serviceDeallocated))
          return
        }
        let results = try self.modelContainer.mainContext.fetch(descriptor)
        promise(.success(results))
      } catch {
        print("Error occured while trying to fetch data for type \(type) from the store : \(error)")
        promise(.failure(.failedToFetchData(error)))
      }
    }.eraseToAnyPublisher()
  }
  
  @MainActor
  func save() {
    do {
      try self.modelContainer.mainContext.save()
    } catch {
      print("Changes could not be saved in SwiftData: \(error)")
    }
  }
}
