//
//  RecordingControlsView.swift
//  Zizh
//
//  Created by Marwan Tutunji on 17/02/2025.
//

import SwiftUI

struct RecordingControlsView: View {
  @StateObject var viewModel: ViewModel.RecordingControls
  @Namespace private var animationNamespace
  
  init(viewModel: ViewModel.RecordingControls = ViewModel.RecordingControls()) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  var body: some View {
    HStack {
      if viewModel.isRecording {
        Spacer()
        Text(viewModel.elapsedTimeString)
          .font(.system(size: 20, weight: .bold, design: .monospaced))
          .foregroundColor(.red)
          .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .opacity
          ))
        Spacer()
      }
      
      // Centered record button
      Button {
          viewModel.toggleRecording()
      } label: {
        RoundedRectangle(cornerRadius: viewModel.isRecording ? 20 : 40)
          .fill(Color.red)
          .frame(width: 80, height: 80)
          .matchedGeometryEffect(id: "recordButton", in: animationNamespace)
      }
      .buttonStyle(.plain)
      .animation(.easeInOut(duration: 0.3), value: viewModel.isRecording)
      
      if viewModel.isRecording {
        Spacer()
        Text(viewModel.elapsedTimeString)
          .font(.system(size: 20, weight: .bold, design: .monospaced))
          .foregroundColor(.red)
          .opacity(0)
        Spacer()
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.black.opacity(0.6))
  }
}

#Preview {
  RecordingControlsView()
}
