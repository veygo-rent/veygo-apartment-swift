//
//  SignatureView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/4/25.
//
import SwiftUI
//这个功能组件内所有UI皆为draft，只是为了测试功能，待改动UI
struct SignatureView: View {
    @State private var lines: [[CGPoint]] = []
    @Binding var savedImage: Image?

    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Please sign below")
                .font(.headline)
                .padding()

            ZStack {
                Color.white
                    .cornerRadius(12)
                    .shadow(radius: 5)

                Path { path in
                    for line in lines {
                        guard let firstPoint = line.first else { continue }
                        path.move(to: firstPoint)
                        for point in line.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.black, lineWidth: 2)
            }
            .clipped()
            .frame(height: 200)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if lines.isEmpty || lines.last?.isEmpty == true {
                            lines.append([value.location])
                        } else {
                            lines[lines.count - 1].append(value.location)
                        }
                    }
                    .onEnded { _ in
                        lines.append([])
                    }
            )

            HStack {
                SecondaryButtonLg(text: "Clear") {
                    lines.removeAll()
                    savedImage = nil
                }

                PrimaryButtonLg(text: "Save") {
                    if let image = renderSignatureImage() {
                        savedImage = Image(uiImage: image)
                        let data = image.pngData()!
                        print("Signature Saved! Datasize: \(data)")
                        let seconds = 0.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            // Put your code which should be executed with a delay here
                            isPresented = false
                        }
                    }
                }
            }

            Button("Close") {
                savedImage = nil
                isPresented = false
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }

    private func renderSignatureImage() -> UIImage? {
        let allPoints = lines.flatMap { $0 }
        guard !allPoints.isEmpty else { return nil }

        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? 0
        let minY = allPoints.map { $0.y }.min() ?? 0
        let maxY = allPoints.map { $0.y }.max() ?? 0

        let padding: CGFloat = 10
        let width = maxX - minX + padding * 2
        let height = maxY - minY + padding * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))

            UIColor.black.setStroke()
            context.cgContext.setLineWidth(2)

            for line in lines {
                guard let firstPoint = line.first else { continue }
                context.cgContext.beginPath()
                context.cgContext.move(to: CGPoint(x: firstPoint.x - minX + padding, y: firstPoint.y - minY + padding))
                for point in line.dropFirst() {
                    context.cgContext.addLine(to: CGPoint(x: point.x - minX + padding, y: point.y - minY + padding))
                }
                context.cgContext.strokePath()
            }
        }
    }
}

#Preview {
    SignatureView(savedImage: .constant(nil as Image?), isPresented: .constant(true))
}
