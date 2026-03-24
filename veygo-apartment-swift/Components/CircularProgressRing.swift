//
//  CircularProgressRing.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/24/26.
//

import SwiftUI

struct CircularProgressRing: View {
    let value: Double
    let total: Double
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.footNote.opacity(0.15), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textBlackPrimary)
                Text("used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 104, height: 104)
    }
}
