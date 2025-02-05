//
//  ContentView.swift
//  Zize
//
//  Created by Marwan Tutunji on 29/01/2025.
//

import SwiftUI

struct HomeView: View {
  @StateObject private var viewModel: HomeViewModel = HomeViewModel()
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      VStack {
        List {
          ForEach(viewModel.recordings, id: \.id) { recording in
            HStack {
              VStack(alignment: .leading) {
                Text("\(recording.name)")
                  .font(.headline)
                Text("\(recording.duration, specifier: "%.2f") sec")
                  .font(.subheadline)
                  .foregroundColor(Color.gray)
              }
              Spacer()
              Text(recording.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())  // Ensures the whole row is tappable
            .onTapGesture {
              // TODO: Handle the taping geture here
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
      .padding()
      .task {
        viewModel.requestPermissions()
        viewModel.syncRecordings()
      }
    }
    .alert(item: $viewModel.deletionErrorMessage) { errorMessage in
      Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
    }
  }
}

#Preview {
  HomeView()
}
