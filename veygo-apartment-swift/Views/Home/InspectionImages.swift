//
//  InspectionImages.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/7/26.
//

import SwiftUI

enum InspectionImageSlot: CaseIterable, Sendable {
    case left, frontLeft, front, frontRight, right, rearRight, back, rearLeft

    var label: String {
        switch self {
        case .left:       return "Left Image"
        case .frontLeft:  return "Front-Left Image"
        case .front:      return "Front Image"
        case .frontRight: return "Front-Right Image"
        case .right:      return "Right Image"
        case .rearRight:  return "Back-Right Image"
        case .back:       return "Back Image"
        case .rearLeft:   return "Back-Left Image"
        }
    }

    var captureTitle: String {
        switch self {
        case .left:       return "Capture Left Image"
        case .frontLeft:  return "Capture Front-left Image"
        case .front:      return "Capture Front Image"
        case .frontRight: return "Capture Front-right Image"
        case .right:      return "Capture Right Image"
        case .rearRight:  return "Capture Rear-right Image"
        case .back:       return "Capture Back Image"
        case .rearLeft:   return "Capture Rear-left Image"
        }
    }
}

struct InspectionImageUpload: Identifiable {
    let id = UUID()
    var filePath: String?
    let image: UIImage
    var uploadFailed = false

    var isUploading: Bool { filePath == nil && !uploadFailed }
}

/// Holds one upload per slot and the bookkeeping around them.
struct InspectionImages {
    private var uploads: [InspectionImageSlot: InspectionImageUpload] = [:]

    subscript(slot: InspectionImageSlot) -> InspectionImageUpload? {
        get { uploads[slot] }
        set { uploads[slot] = newValue }
    }

    /// First slot with no image, in capture order.
    var nextSlot: InspectionImageSlot? {
        InspectionImageSlot.allCases.first { uploads[$0] == nil }
    }

    var nextCaptureTitle: String {
        nextSlot?.captureTitle ?? "All photos captured"
    }

    var allCaptured: Bool {
        InspectionImageSlot.allCases.allSatisfy { uploads[$0] != nil }
    }

    var allUploaded: Bool {
        InspectionImageSlot.allCases.allSatisfy { uploads[$0]?.filePath != nil }
    }

    func path(for slot: InspectionImageSlot) -> String? {
        uploads[slot]?.filePath
    }

    /// Reserve the next open slot for a freshly captured image.
    mutating func reserve(_ image: UIImage) -> (slot: InspectionImageSlot, id: UUID)? {
        guard let slot = nextSlot else { return nil }
        let upload = InspectionImageUpload(image: image)
        uploads[slot] = upload
        return (slot, upload.id)
    }

    mutating func complete(slot: InspectionImageSlot, id: UUID, filePath: String) {
        guard var upload = uploads[slot], upload.id == id else { return }
        upload.filePath = filePath
        upload.uploadFailed = false
        uploads[slot] = upload
    }

    mutating func fail(slot: InspectionImageSlot, id: UUID) {
        guard var upload = uploads[slot], upload.id == id else { return }
        upload.filePath = nil
        upload.uploadFailed = true
        uploads[slot] = upload
    }

    mutating func removeAll() {
        uploads.removeAll()
    }
}

/// A single tile in the inspection grid.
struct InspectionImageTile: View {
    let slot: InspectionImageSlot
    let upload: InspectionImageUpload?
    let onRemove: () -> Void

    private let corner: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.label)
                .font(.footnote)
                .foregroundStyle(.textBlackPrimary)

            ZStack(alignment: .topTrailing) {
                if let upload {
                    ZStack {
                        GeometryReader { geo in
                            Image(uiImage: upload.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }
                        if upload.isUploading {
                            Rectangle().fill(.black.opacity(0.35))
                            VStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Uploading")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        } else if upload.uploadFailed {
                            Rectangle().fill(.black.opacity(0.45))
                            Text("Upload failed")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.red.opacity(0.85), in: Capsule())
                        }
                    }
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .symbolRenderingMode(.multicolor)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(slot.label)")
                } else {
                    RoundedRectangle(cornerRadius: corner)
                        .strokeBorder(.gray.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                        .frame(height: 140)
                        .overlay {
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .foregroundStyle(.textBlackSecondary)
                                Text("Not captured")
                                    .font(.footnote)
                                    .foregroundStyle(.textBlackSecondary)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
