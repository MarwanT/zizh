//
//  ContentView.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel: ViewModel = ViewModel()
  
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
    .task {
      viewModel.requestPermissions()
    }
  }
}

#Preview {
  ContentView()
}
