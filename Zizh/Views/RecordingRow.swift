//
//  RecordingRow.swift
//  Zizh
//
//  Created by Marwan Tutunji on 08/02/2025.
//

import SwiftUI

struct RecordingRow: View {
  let recordEntity: any RecordDataEntity
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
          Text(recordEntity.name)
            .font(.headline)
            .foregroundColor(Color.white)
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
  let recording = RecordingData(
    id: UUID(),
    duration: 123.45,
    name: "Test Recording",
    address: URL(filePath: "file://zouzou.wave"),
    createdAt: Date()
  )
  RecordingRow(recordEntity: recording)
    .background(Color.black)
}
