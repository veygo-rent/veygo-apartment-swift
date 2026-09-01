//
//  AdminVehicleSubmissionView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 12/22/25.
//

import SwiftUI
import CodeScanner
internal import AVFoundation

struct AdminVehicleSubmissionView: View {
    enum InspectionImageSlot: CaseIterable, Sendable {
        case left, frontLeft, front, frontRight, right, rearRight, back, rearLeft

        var label: String {
            switch self {
            case .left: return "Left Image"
            case .frontLeft: return "Front-Left Image"
            case .front: return "Front Image"
            case .frontRight: return "Front-Right Image"
            case .right: return "Right Image"
            case .rearRight: return "Back-Right Image"
            case .back: return "Back Image"
            case .rearLeft: return "Back-Left Image"
            }
        }

        var captureButtonTitle: String {
            switch self {
            case .left: return "Capture Left Image"
            case .frontLeft: return "Capture Front-left Image"
            case .front: return "Capture Front Image"
            case .frontRight: return "Capture Front-right Image"
            case .right: return "Capture Right Image"
            case .rearRight: return "Capture Rear-right Image"
            case .back: return "Capture Back Image"
            case .rearLeft: return "Capture Rear-left Image"
            }
        }

        var bodyKey: String {
            switch self {
            case .left: return "left_image_path"
            case .right: return "right_image_path"
            case .front: return "front_image_path"
            case .back: return "back_image_path"
            case .frontRight: return "front_right_image_path"
            case .frontLeft: return "front_left_image_path"
            case .rearRight: return "back_right_image_path"
            case .rearLeft: return "back_left_image_path"
            }
        }
    }

    struct InspectionImageUpload: Identifiable {
        let id = UUID()
        var filePath: String?
        let image: UIImage
        var uploadFailed = false

        var isUploading: Bool {
            filePath == nil && !uploadFailed
        }
    }

    @Environment(Session.self) private var session

    @State private var vinInput: String = ""
    @State private var isScanningVin: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearScreenOnDismiss: Bool = false

    @State private var isSubmitting: Bool = false
    @State private var isShowingCamera = false

    @State private var images: [InspectionImageSlot: InspectionImageUpload] = [:]

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                HStack(spacing: 18) {
                    TextInputField(text: $vinInput, placeholder: "VIN Number")
                        .disabled(true)
                    SecondaryButton(text: "Scan") {
                        vinInput = ""
                        isScanningVin = true
                    }
                    .frame(width: 86)
                    .sheet(isPresented: $isScanningVin) {
                        CodeScannerView(codeTypes: [.code39, .qr], shouldVibrateOnSuccess: false) { response in
                            if case let .success(result) = response {
                                let cleaned = result.string
                                    .uppercased()
                                    .replacingOccurrences(of: " ", with: "")
                                    .replacingOccurrences(of: "\n", with: "")
                                    .replacingOccurrences(of: "\t", with: "")
                                let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHJKLMNPRSTUVWXYZ0123456789")
                                if cleaned.count == 17,
                                   cleaned.rangeOfCharacter(from: allowedCharacters.inverted) == nil {
                                    vinInput = cleaned
                                    isScanningVin = false
                                }
                            }
                        }
                        .ignoresSafeArea(.all)
                    }
                    .sensoryFeedback(.selection, trigger: vinInput)
                }
                if !vinInput.isEmpty {
                    SecondaryButton(text: nextCaptureButtonTitle) {
                        isShowingCamera = true
                    }
                    .padding(.top)
                    .disabled(allImagesCaptured)
                    PrimaryButton(text: "Submit Vehicle Images") {
                        Task { await generateSnapshot() }
                    }
                    .padding(.top)
                    .disabled(isSubmitting || !allImageUploadsComplete)

                    LazyVGrid(columns: gridColumns, spacing: 36) {
                        ForEach(InspectionImageSlot.allCases, id: \.self) { slot in
                            imageTile(slot: slot)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.mainBG.ignoresSafeArea(.all))
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraImagePicker { image in
                if let data = image.heicData() {
                    Task {
                        guard let reservation = reserveImageSlot(image) else { return }
                        await uploadImage(
                            data: data,
                            fileName: "vehicle_inspection_camera_\(reservation.1.uuidString).heic",
                            slot: reservation.0,
                            uploadId: reservation.1
                        )
                    }
                } else {
                    present(title: "Camera Error", message: "Failed to read captured image.")
                }
            }
            .ignoresSafeArea(edges: .all)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearScreenOnDismiss {
                    vinInput = ""
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: vinInput) { _, _ in
            images.removeAll()
        }
    }

    // MARK: - Grid / tiles

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    @ViewBuilder
    private func imageTile(slot: InspectionImageSlot) -> some View {
        let tileCorner: CGFloat = 16
        let label = slot.label

        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.textBlackPrimary)

            ZStack(alignment: .topTrailing) {
                if let upload = images[slot] {
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
                    .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))

                    Button {
                        images[slot] = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .symbolRenderingMode(.multicolor)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(label)")
                } else {
                    RoundedRectangle(cornerRadius: tileCorner)
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

    // MARK: - Capture progress helpers

    private var nextCaptureButtonTitle: String {
        nextCaptureSlot()?.captureButtonTitle ?? "All photos captured"
    }

    private var allImagesCaptured: Bool {
        images.count == InspectionImageSlot.allCases.count
    }

    private var allImageUploadsComplete: Bool {
        InspectionImageSlot.allCases.allSatisfy { images[$0]?.filePath != nil }
    }

    private func nextCaptureSlot() -> InspectionImageSlot? {
        InspectionImageSlot.allCases.first { images[$0] == nil }
    }

    private func reserveImageSlot(_ image: UIImage) -> (InspectionImageSlot, UUID)? {
        guard let slot = nextCaptureSlot() else { return nil }
        let upload = InspectionImageUpload(image: image)
        images[slot] = upload
        return (slot, upload.id)
    }

    private func completeImageUpload(slot: InspectionImageSlot, id: UUID, filePath: String) {
        updateImageUpload(slot: slot, id: id) { upload in
            upload.filePath = filePath
            upload.uploadFailed = false
        }
    }

    private func failImageUpload(slot: InspectionImageSlot, id: UUID) {
        updateImageUpload(slot: slot, id: id) { upload in
            upload.filePath = nil
            upload.uploadFailed = true
        }
    }

    private func updateImageUpload(slot: InspectionImageSlot, id: UUID, update: (inout InspectionImageUpload) -> Void) {
        guard var upload = images[slot], upload.id == id else { return }
        update(&upload)
        images[slot] = upload
    }

    // MARK: - Upload one image (signed-URL flow)
    //
    // 1. Ask our backend for a signed Google upload URL for this VIN + filename.
    // 2. PUT the raw bytes straight to that signed URL (no auth headers).
    // 3. Keep the returned file_name (UUID) as the path for generate-snapshot.

    private func uploadImage(data: Data, fileName: String, slot: InspectionImageSlot, uploadId: UUID) async {
        do {
            let link = try await requestUploadLink(fileName: fileName)
            try await putToSignedURL(link.fileLink, data: data, contentType: contentType(for: fileName))
            
            completeImageUpload(slot: slot, id: uploadId, filePath: link.fileName)
        } catch let error as VeygoError {
            failImageUpload(slot: slot, id: uploadId)
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            failImageUpload(slot: slot, id: uploadId)
            present(.E_DEFAULT)
        }
    }

    /// Step 1 — ask the backend for a signed upload link.
    private func requestUploadLink(fileName: String) async throws -> FileLink {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let body = [
            "vehicle_vin": vinInput,
            "file_name": fileName
        ]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/vehicle/request-upload-link",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(FileLink.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    /// Step 2 — PUT the raw bytes to the Google signed URL. This is NOT a
    /// veygoCurlRequest (that would prepend our base path and headers); it's a
    /// plain request to the absolute signed URL with only Content-Type.
    private func putToSignedURL(_ urlString: String, data: Data, contentType: String) async throws {
        guard let url = URL(string: urlString) else {
            throw VeygoError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300

        do {
            let (_, response) = try await URLSession.shared.upload(for: request, from: data)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            // Google returns 200 (or 201) on a successful signed-URL PUT.
            guard (200...299).contains(httpResponse.statusCode) else {
                throw VeygoError.server(status: httpResponse.statusCode, error: .E_DEFAULT)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    /// Match the Content-Type the backend signed the URL with (by extension).
    private func contentType(for fileName: String) -> String {
        switch (fileName as NSString).pathExtension.uppercased() {
        case "PDF":          return "application/pdf"
        case "JPG", "JPEG":  return "image/jpeg"
        case "PNG":          return "image/png"
        case "CSV":          return "text/csv"
        case "HEIC":         return "image/heic"
        default:             return "application/octet-stream"
        }
    }

    // MARK: - Generate snapshot

    private func generateSnapshot() async {
        isSubmitting = true
        defer { isSubmitting = false }

        guard allImageUploadsComplete else {
            present(title: "Missing Photos",
                    message: "Please wait for all images to finish uploading before submitting.")
            return
        }

        var body = ["vehicle_vin": vinInput]
        for slot in InspectionImageSlot.allCases {
            body[slot.bodyKey] = images[slot]?.filePath
        }

        do {
            let snapshot = try await generateSnapshotRequest(body: body)
            clearScreenOnDismiss = true
            present(title: "Success", message: "Snapshot generated successfully. ID: \(snapshot.id)")
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func generateSnapshotRequest(body: [String: String]) async throws -> VehicleSnapshot {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/vehicle/generate-snapshot",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 201 {
                return try VeygoJsonStandard.shared.decoder.decode(VehicleSnapshot.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
