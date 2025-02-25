//
//  RecordingsListView.swift
//  Zizh
//
//  Created by Marwan Tutunji on 19/02/2025.
//

import SwiftUI

struct AudioRecordingsListView: View {
  @StateObject var viewModel: ViewModel.AudioList
  
  var body: some View {
    List {
      ForEach(viewModel.records, id: \.id) { recording in
        AudioRecordingRow(recordEntity: recording) { id, newName in
          Task {
            try await viewModel.updateRecording(id, name: newName).async()
          }
        }
        .contentShape(Rectangle())  // Ensures the whole row is tappable
        .onTapGesture {
          viewModel.handleRecordingTap(recording)
        }
        .listRowBackground(
          viewModel.highlightedRecording == recording.id ?
          Color.black : Color.white.opacity(0.1))
      }
      .onDelete(perform: viewModel.deleteRecording)
    }
    .scrollContentBackground(.hidden) // Hides the default List background
    .background(Color.black)
  }
}
