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
        AudioRecordingsListView(viewModel: viewModel.audioListViewModel)
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
        .contentMargins(.bottom, 100, for: .scrollContent)
        .padding(.bottom, 16)
        VStack {
          Spacer()
          RecordingControlsView(viewModel: viewModel.recordingControlsViewModel)
        }
      }
      .padding(.bottom, 18)
      .ignoresSafeArea(.all, edges: .bottom)
      .task {
        viewModel.requestPermissions()
        try? await viewModel.syncRecordings().async()
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
  HomeView(viewModel: ViewModel.Home())
}
