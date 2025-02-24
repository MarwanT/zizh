//
//  RecordingRow.swift
//  Zizh
//
//  Created by Marwan Tutunji on 08/02/2025.
//

import SwiftUI

struct AudioRecordingRow: View {
  @State private var isEditingName: Bool = false
  @State private var recordingName: String
  @FocusState private var nameFieldIsFocused: Bool
  
  let onNameChange: ((UUID, String) -> Void)?
  
  let recordEntity: any AudioRecord
  
  init(recordEntity: any AudioRecord, onNameChange: ((UUID, String) -> Void)? = nil) {
    self.recordEntity = recordEntity
    self.onNameChange = onNameChange
    recordingName = "\(recordEntity.name)"
    nameFieldIsFocused = false
  }
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        if isEditingName {
          TextField(
            "Recording Name",
            text: $recordingName
          )
          .focused($nameFieldIsFocused)
          .onSubmit {
            // TODO: Handle submit | Validate
            isEditingName = false
            nameFieldIsFocused = false
            if (recordEntity.name != recordingName) {
              onNameChange?(recordEntity.id, recordingName)
            }
          }
          .disableAutocorrection(true)
          .foregroundStyle(Color.white)
        } else {
          Text(recordEntity.name)
            .font(.headline)
            .foregroundColor(Color.white)
            .onTapGesture(perform: {
              isEditingName.toggle()
              nameFieldIsFocused = true
            })
          
        }
        Text("\(recordEntity.duration, specifier: "%.2f") sec")
          .font(.subheadline)
          .foregroundColor(Color.gray)
      }
      Spacer()
      Text(recordEntity.createdAt, style: .date)
        .font(.caption)
        .foregroundColor(.gray)
    }
    .padding(.vertical, 5)
  }
}

#Preview {
  let recording = AudioRecordData(
    id: UUID(),
    duration: 123.45,
    name: "Test Recording",
    address: URL(filePath: "file://zouzou.wave"),
    createdAt: Date()
  )
  AudioRecordingRow(recordEntity: recording)
    .background(Color.black)
}
