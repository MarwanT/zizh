//
//  IdentifiableMessages.swift
//  Zize
//
//  Created by Marwan Tutunji on 05/02/2025.
//

import Foundation

struct IdentifiableMessages: Identifiable {
    let id = UUID()
    let message: String
}
