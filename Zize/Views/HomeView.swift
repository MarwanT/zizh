//
//  ContentView.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import SwiftUI

struct HomeView: View {
  @StateObject private var viewModel: ViewModel = ViewModel()
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      VStack {
        List {
          ForEach(viewModel.recordings) { recording in
            Text(recording.name)
          }
        }
        Spacer()
        Button {
          withAnimation(.easeOut(duration: 1)) {
            viewModel.toggleRecording()
          }
        } label: {
          RoundedRectangle(cornerRadius: viewModel.isRecording ? 20 : 40)
            .fill(Color.red)
            .frame(width: 80, height: 80)
        }
      }
      .padding()
      .task {
        viewModel.requestPermissions()
        viewModel.syncRecordings()
      }
    }
  }
}

#Preview {
  HomeView()
}
