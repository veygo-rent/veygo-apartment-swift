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
    enum InspectionImageSlot: Sendable {
        case left, frontLeft, front, frontRight, right, rearRight, back, rearLeft
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

    @State private var leftImage: InspectionImageUpload? = nil
    @State private var rightImage: InspectionImageUpload? = nil
    @State private var frontImage: InspectionImageUpload? = nil
    @State private var backImage: InspectionImageUpload? = nil
    @State private var rearRight: InspectionImageUpload? = nil
    @State private var rearLeft: InspectionImageUpload? = nil
    @State private var frontRight: InspectionImageUpload? = nil
    @State private var frontLeft: InspectionImageUpload? = nil

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
                        imageTile(label: "Left Image", binding: $leftImage)
                        imageTile(label: "Front-Left Image", binding: $frontLeft)
                        imageTile(label: "Front Image", binding: $frontImage)
                        imageTile(label: "Front-Right Image", binding: $frontRight)
                        imageTile(label: "Right Image", binding: $rightImage)
                        imageTile(label: "Back-Right Image", binding: $rearRight)
                        imageTile(label: "Back Image", binding: $backImage)
                        imageTile(label: "Back-Left Image", binding: $rearLeft)
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
            leftImage = nil
            rightImage = nil
            frontLeft = nil
            frontRight = nil
            rearLeft = nil
            rearRight = nil
            frontImage = nil
            backImage = nil
        }
    }

    // MARK: - Grid / tiles

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    @ViewBuilder
    private func imageTile(label: String, binding: Binding<InspectionImageUpload?>) -> some View {
        let tileCorner: CGFloat = 16

        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.textBlackPrimary)

            ZStack(alignment: .topTrailing) {
                if let upload = binding.wrappedValue {
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
                        binding.wrappedValue = nil
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
        if leftImage == nil { return "Capture Left Image" }
        else if frontLeft == nil { return "Capture Front-left Image" }
        else if frontImage == nil { return "Capture Front Image" }
        else if frontRight == nil { return "Capture Front-right Image" }
        else if rightImage == nil { return "Capture Right Image" }
        else if rearRight == nil { return "Capture Rear-right Image" }
        else if backImage == nil { return "Capture Back Image" }
        else if rearLeft == nil { return "Capture Rear-left Image" }
        else { return "All photos captured" }
    }

    private var allImagesCaptured: Bool {
        leftImage != nil && rightImage != nil && frontImage != nil && backImage != nil &&
        rearRight != nil && rearLeft != nil && frontRight != nil && frontLeft != nil
    }

    private var allImageUploadsComplete: Bool {
        leftImage?.filePath != nil && rightImage?.filePath != nil &&
        frontImage?.filePath != nil && backImage?.filePath != nil &&
        rearRight?.filePath != nil && rearLeft?.filePath != nil &&
        frontRight?.filePath != nil && frontLeft?.filePath != nil
    }

    private func nextCaptureSlot() -> InspectionImageSlot? {
        if leftImage == nil { return .left }
        else if frontLeft == nil { return .frontLeft }
        else if frontImage == nil { return .front }
        else if frontRight == nil { return .frontRight }
        else if rightImage == nil { return .right }
        else if rearRight == nil { return .rearRight }
        else if backImage == nil { return .back }
        else if rearLeft == nil { return .rearLeft }
        else { return nil }
    }

    private func reserveImageSlot(_ image: UIImage) -> (InspectionImageSlot, UUID)? {
        guard let slot = nextCaptureSlot() else { return nil }
        let upload = InspectionImageUpload(image: image)

        switch slot {
        case .left:       leftImage = upload
        case .frontLeft:  frontLeft = upload
        case .front:      frontImage = upload
        case .frontRight: frontRight = upload
        case .right:      rightImage = upload
        case .rearRight:  rearRight = upload
        case .back:       backImage = upload
        case .rearLeft:   rearLeft = upload
        }
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
        switch slot {
        case .left:
            guard var upload = leftImage, upload.id == id else { return }
            update(&upload); leftImage = upload
        case .frontLeft:
            guard var upload = frontLeft, upload.id == id else { return }
            update(&upload); frontLeft = upload
        case .front:
            guard var upload = frontImage, upload.id == id else { return }
            update(&upload); frontImage = upload
        case .frontRight:
            guard var upload = frontRight, upload.id == id else { return }
            update(&upload); frontRight = upload
        case .right:
            guard var upload = rightImage, upload.id == id else { return }
            update(&upload); rightImage = upload
        case .rearRight:
            guard var upload = rearRight, upload.id == id else { return }
            update(&upload); rearRight = upload
        case .back:
            guard var upload = backImage, upload.id == id else { return }
            update(&upload); backImage = upload
        case .rearLeft:
            guard var upload = rearLeft, upload.id == id else { return }
            update(&upload); rearLeft = upload
        }
    }

    // MARK: - Upload one image

    private func uploadImage(data: Data, fileName: String, slot: InspectionImageSlot, uploadId: UUID) async {
        do {
            let filePath = try await uploadImageRequest(data: data, fileName: fileName)
            completeImageUpload(slot: slot, id: uploadId, filePath: filePath)
        } catch let error as VeygoError {
            failImageUpload(slot: slot, id: uploadId)
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            failImageUpload(slot: slot, id: uploadId)
            present(.E_DEFAULT)
        }
    }

    private func uploadImageRequest(data: Data, fileName: String) async throws -> String {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/vehicle/upload-image",
            method: .post,
            headers: [
                "auth": "\(token)$\(userId)",
                "Content-Type": "application/octet-stream",
                "file-name": fileName,
                "vehicle-vin": vinInput
            ],
            timeout: 300
        )
        do {
            let (respData, response) = try await URLSession.shared.upload(for: request, from: data)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 201 {
                let decoded = try VeygoJsonStandard.shared.decoder.decode(FilePath.self, from: respData)
                return decoded.filePath
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: respData)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: respData)
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

    // MARK: - Generate snapshot

    private func generateSnapshot() async {
        isSubmitting = true
        defer { isSubmitting = false }

        // All paths must be present before submitting.
        guard
            let leftImagePath = leftImage?.filePath,
            let rightImagePath = rightImage?.filePath,
            let frontImagePath = frontImage?.filePath,
            let backImagePath = backImage?.filePath,
            let frontRightImagePath = frontRight?.filePath,
            let frontLeftImagePath = frontLeft?.filePath,
            let backRightImagePath = rearRight?.filePath,
            let backLeftImagePath = rearLeft?.filePath
        else {
            present(title: "Missing Photos",
                    message: "Please wait for all images to finish uploading before submitting.")
            return
        }

        let body = [
            "vehicle_vin": vinInput,
            "left_image_path": leftImagePath,
            "right_image_path": rightImagePath,
            "front_image_path": frontImagePath,
            "back_image_path": backImagePath,
            "front_right_image_path": frontRightImagePath,
            "front_left_image_path": frontLeftImagePath,
            "back_right_image_path": backRightImagePath,
            "back_left_image_path": backLeftImagePath
        ]

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
