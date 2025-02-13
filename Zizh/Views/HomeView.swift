//
//  ContentView.swift
//  Zizh
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import SwiftUI

struct HomeView: View {
  @State private var isEditing = false
  @State private var editedText: String = ""
  @State private var isShowingAlert = false
  @StateObject private var viewModel: ViewModel.Home
  
  init(viewModel: ViewModel.Home = ViewModel.Home()) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()
        VStack {
          List {
            ForEach(viewModel.recordings, id: \.id) { recording in
              RecordingRow(recording: recording)
                .contentShape(Rectangle())  // Ensures the whole row is tappable
                .onTapGesture {
                  viewModel.handleRecordingTap(recording)
                }.listRowBackground(
                  viewModel.currentPlayingId == recording.id ?
                  Color.black :
                    Color.white.opacity(0.1)
                )
            }
            .onDelete(perform: viewModel.deleteRecording)
          }
          .scrollContentBackground(.hidden) // Hides the default List background
          .background(Color.black)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button(action: {
                editedText = "\(viewModel.rate)"
                isShowingAlert = true
              }) {
                Text("\(viewModel.rate, specifier: "%.4f")")
              }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
              Button(action: {
                viewModel.toggleSlowMotionOn()
              }) {
                Image("sea-turtle")
                  .renderingMode(.template)
                  .resizable()           // Makes the image resizable
                  .scaledToFit()         // Maintains the aspect ratio to fit within the frame
                  .frame(width: 24, height: 24)
              }.tint(viewModel.isSlowMotion ? Color.green : Color.gray)
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
      .alert("Edit Value", isPresented: $isShowingAlert) {
        TextField("Enter new value", text: $editedText) // Editable text field
        Button("Cancel", role: .cancel) { }
        Button("Done") {
            if let newRate = Float(editedText) {
                viewModel.rate = newRate
            }
        }
    } message: {
        Text("Enter a new value:")
    }
    }
  }
}

#Preview {
  HomeView(viewModel: ViewModel.Home.preview)
}
