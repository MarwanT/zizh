//
//  RecordingView.swift
//  Zizh
//
//  Created by Marwan Tutunji on 17/02/2025.
//

import SwiftUI

struct RecordingView: View {
  @StateObject var viewModel: ViewModel.Recording
  
  init(viewModel: ViewModel.Recording = ViewModel.Recording()) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  var body: some View {
    VStack {
      Spacer()
      // Add recording timer and button in HStack
      // Modified recording controls
      ZStack {
        // Timer positioned to the left
        HStack {
          if viewModel.isRecording {
            Text(viewModel.elapsedTimeString)
              .font(.system(size: 20, weight: .bold, design: .monospaced))
              .foregroundColor(.red)
              .transition(.asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .opacity
              ))
              .padding(.leading, 20)
            Spacer() // Push timer to left
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        
        // Centered record button
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
      .padding(18)
      .background(Color.black.opacity(0.6))
    }
  }
}

#Preview {
  RecordingView()
}
