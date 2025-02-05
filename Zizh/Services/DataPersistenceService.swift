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

enum DataPersistenceError: Error {
  case failedToFetchData(Error)
  case serviceDeallocated
}

@MainActor
protocol DataPersistenceService {
  func add(item: any Persistable)
  func remove(item: any Persistable)
  func fetchAll<T: Persistable>(_ type: T.Type, sortBy: [SortDescriptor<T>]) -> AnyPublisher<[T], DataPersistenceError>
  func fetchAll<T: Persistable>(_ type: T.Type) -> AnyPublisher<[T], DataPersistenceError>
}

class SwiftDataService: DataPersistenceService {
  let modelContainer: ModelContainer
  let mainContext: ModelContext
  
  init(types: [any Persistable.Type] = [Recording.self], isStoredInMemoryOnly: Bool = false) throws {
    let schema = Schema(types)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
    modelContainer = try ModelContainer(for: schema, configurations: configuration)
    mainContext = self.modelContainer.mainContext
  }
  
  
  func add(item: any Persistable) {
    mainContext.insert(item)
  }
  
  func remove(item: any Persistable) {
    mainContext.delete(item)
  }
  
  func fetchAll<T>(_ type: T.Type) -> AnyPublisher<[T], DataPersistenceError> where T : PersistentModel {
    return fetchAll(type, sortBy: [])
  }
  
  func fetchAll<T>(_ type: T.Type, sortBy: [SortDescriptor<T>] = []) -> AnyPublisher<[T], DataPersistenceError> where T : PersistentModel {
    return Future<[T], DataPersistenceError> { [weak self] promise in
      let descriptor = FetchDescriptor<T>(sortBy: sortBy)
      do {
        guard let self = self else {
          promise(.failure(.serviceDeallocated))
          return
        }
        let results = try self.mainContext.fetch(descriptor)
        promise(.success(results))
      } catch {
        print("Error occured while trying to fetch data for type \(type) from the store : \(error)")
        promise(.failure(.failedToFetchData(error)))
      }
    }.eraseToAnyPublisher()
  }
}
