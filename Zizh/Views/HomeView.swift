//
//  ContentView.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import SwiftUI

struct HomeView: View {
  @StateObject private var viewModel: ViewModel.Home = ViewModel.Home()
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      VStack {
        List {
          ForEach(viewModel.recordings, id: \.id) { recording in
            RecordingRow(recording: recording)
              .contentShape(Rectangle())  // Ensures the whole row is tappable
              .onTapGesture {
                viewModel.handleRecordingTap(recording)
              }
          }
          .onDelete(perform: viewModel.deleteRecording)
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
      .task {
        viewModel.requestPermissions()
        viewModel.syncRecordings()
      }
    }
    .alert(item: $viewModel.deletionErrorMessage) { errorMessage in
      Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
    }
    .alert(item: $viewModel.audioPlayerAlertMessage) { warning in
      Alert(title: Text("Audio Player Message"), message: Text(warning.message), dismissButton: .default(Text("OK")))
    }
  }
}

#Preview {
  HomeView()
}
