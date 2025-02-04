//
//  CombineExtensions.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

extension AsyncSequence {
    func first() async rethrows -> Element? {
        try await first(where: { _ in true})
    }
}
