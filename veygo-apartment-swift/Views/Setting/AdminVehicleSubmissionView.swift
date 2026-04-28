//
//  AdminVehicleSubmissionView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 12/22/25.
//

import SwiftUI
import CodeScanner

struct AdminVehicleSubmissionView: View {
    enum InspectionImageSlot: Sendable {
        case left
        case frontLeft
        case front
        case frontRight
        case right
        case rearRight
        case back
        case rearLeft
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

    @State private var vinInput: String = ""
    @State private var isScanningVin: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
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
    
    @State private var clearScreen: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                HStack (spacing: 18) {
                    TextInputField(placeholder: "VIN Number", text: $vinInput)
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
                                   cleaned.rangeOfCharacter(from: allowedCharacters.inverted) == nil{
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
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await generateSnapshotAsync(
                                    token,
                                    userId
                                )
                            }
                        }
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
        .background(Color("MainBG").ignoresSafeArea(.all))
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraImagePicker { image in
                // Convert to Data and upload
                if let data = image.heicData() {
                    Task {
                        guard let reservation = reserveImageSlot(image) else { return }
                        await ApiCallActor.shared.appendApi { token, userId in
                            await submitFileAsync(
                                token,
                                userId,
                                data,
                                "vehicle_inspection_camera_\(reservation.1.uuidString).heic",
                                reservation.0,
                                reservation.1
                            )
                        }
                    }
                } else {
                    // optional: show an error alert here
                    alertMessage = "Failed to read captured image."
                    alertTitle = "Camera Error"
                    showAlert = true
                }
            }
            .ignoresSafeArea(edges: .all)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearScreen {
                    vinInput = ""
                }
                if clearUserTriggered {
                    session.user = nil
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
                            Rectangle()
                                .fill(.black.opacity(0.35))

                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Uploading")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        } else if upload.uploadFailed {
                            Rectangle()
                                .fill(.black.opacity(0.45))

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
    
    private var nextCaptureButtonTitle: String {
        if leftImage == nil {
            return "Capture Left Image"
        } else if frontLeft == nil {
            return "Capture Front-left Image"
        } else if frontImage == nil {
            return "Capture Front Image"
        } else if frontRight == nil {
            return "Capture Front-right Image"
        } else if rightImage == nil {
            return "Capture Right Image"
        } else if rearRight == nil {
            return "Capture Rear-right Image"
        } else if backImage == nil {
            return "Capture Back Image"
        } else if rearLeft == nil {
            return "Capture Rear-left Image"
        } else {
            return "All photos captured"
        }
    }
    
    private var allImagesCaptured: Bool {
        leftImage != nil &&
        rightImage != nil &&
        frontImage != nil &&
        backImage != nil &&
        rearRight != nil &&
        rearLeft != nil &&
        frontRight != nil &&
        frontLeft != nil
    }

    private var allImageUploadsComplete: Bool {
        leftImage?.filePath != nil &&
        rightImage?.filePath != nil &&
        frontImage?.filePath != nil &&
        backImage?.filePath != nil &&
        rearRight?.filePath != nil &&
        rearLeft?.filePath != nil &&
        frontRight?.filePath != nil &&
        frontLeft?.filePath != nil
    }

    private func nextCaptureSlot() -> InspectionImageSlot? {
        if leftImage == nil {
            return .left
        } else if frontLeft == nil {
            return .frontLeft
        } else if frontImage == nil {
            return .front
        } else if frontRight == nil {
            return .frontRight
        } else if rightImage == nil {
            return .right
        } else if rearRight == nil {
            return .rearRight
        } else if backImage == nil {
            return .back
        } else if rearLeft == nil {
            return .rearLeft
        } else {
            return nil
        }
    }

    @MainActor
    private func reserveImageSlot(_ image: UIImage) -> (InspectionImageSlot, UUID)? {
        guard let slot = nextCaptureSlot() else { return nil }
        let upload = InspectionImageUpload(image: image)

        switch slot {
        case .left:
            leftImage = upload
        case .frontLeft:
            frontLeft = upload
        case .front:
            frontImage = upload
        case .frontRight:
            frontRight = upload
        case .right:
            rightImage = upload
        case .rearRight:
            rearRight = upload
        case .back:
            backImage = upload
        case .rearLeft:
            rearLeft = upload
        }

        return (slot, upload.id)
    }

    @MainActor
    private func completeImageUpload(slot: InspectionImageSlot, id: UUID, filePath: String) {
        updateImageUpload(slot: slot, id: id) { upload in
            upload.filePath = filePath
            upload.uploadFailed = false
        }
    }

    @MainActor
    private func failImageUpload(slot: InspectionImageSlot, id: UUID) {
        updateImageUpload(slot: slot, id: id) { upload in
            upload.filePath = nil
            upload.uploadFailed = true
        }
    }

    @MainActor
    private func updateImageUpload(slot: InspectionImageSlot, id: UUID, update: (inout InspectionImageUpload) -> Void) {
        switch slot {
        case .left:
            guard var upload = leftImage, upload.id == id else { return }
            update(&upload)
            leftImage = upload
        case .frontLeft:
            guard var upload = frontLeft, upload.id == id else { return }
            update(&upload)
            frontLeft = upload
        case .front:
            guard var upload = frontImage, upload.id == id else { return }
            update(&upload)
            frontImage = upload
        case .frontRight:
            guard var upload = frontRight, upload.id == id else { return }
            update(&upload)
            frontRight = upload
        case .right:
            guard var upload = rightImage, upload.id == id else { return }
            update(&upload)
            rightImage = upload
        case .rearRight:
            guard var upload = rearRight, upload.id == id else { return }
            update(&upload)
            rearRight = upload
        case .back:
            guard var upload = backImage, upload.id == id else { return }
            update(&upload)
            backImage = upload
        case .rearLeft:
            guard var upload = rearLeft, upload.id == id else { return }
            update(&upload)
            rearLeft = upload
        }
    }
    
    @ApiCallActor func submitFileAsync (_ token: String, _ userId: Int, _ file: Data, _ fileName: String, _ slot: InspectionImageSlot, _ uploadId: UUID) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                let request = veygoCurlRequest(
                    url: "/api/v1/vehicle/upload-image",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)",
                        "Content-Type": "application/octet-stream",
                        "file-name": fileName,
                        "vehicle-vin": await vinInput
                    ],
                    timeout: 300
                )
                
                let (data, response) = try await URLSession.shared.upload(for: request, from: file)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        failImageUpload(slot: slot, id: uploadId)
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    if let decodedString = String(data: data, encoding: .utf8) {
                            print("Decoded String: \(decodedString)")
                        } else {
                            print("Decoding failed.")
                        }
                    await MainActor.run {
                        failImageUpload(slot: slot, id: uploadId)
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 201:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FilePath.self, from: data) else {
                        await MainActor.run {
                            failImageUpload(slot: slot, id: uploadId)
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        completeImageUpload(slot: slot, id: uploadId, filePath: decodedBody.filePath)
                    }
                    return .doNothing
                case 400:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) else {
                        let msg = ErrorResponse.E400
                        await MainActor.run {
                            failImageUpload(slot: slot, id: uploadId)
                            alertTitle = msg.title
                            alertMessage = msg.message
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        failImageUpload(slot: slot, id: uploadId)
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                    return .doNothing
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            failImageUpload(slot: slot, id: uploadId)
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            failImageUpload(slot: slot, id: uploadId)
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            failImageUpload(slot: slot, id: uploadId)
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            failImageUpload(slot: slot, id: uploadId)
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        failImageUpload(slot: slot, id: uploadId)
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                failImageUpload(slot: slot, id: uploadId)
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
    
    @ApiCallActor func generateSnapshotAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let payload = await MainActor.run {
                    (
                        vehicleVin: vinInput,
                        leftImagePath: leftImage?.filePath,
                        rightImagePath: rightImage?.filePath,
                        frontImagePath: frontImage?.filePath,
                        backImagePath: backImage?.filePath,
                        frontRightImagePath: frontRight?.filePath,
                        frontLeftImagePath: frontLeft?.filePath,
                        backRightImagePath: rearRight?.filePath,
                        backLeftImagePath: rearLeft?.filePath
                    )
                }

                guard
                    let leftImagePath = payload.leftImagePath,
                    let rightImagePath = payload.rightImagePath,
                    let frontImagePath = payload.frontImagePath,
                    let backImagePath = payload.backImagePath,
                    let frontRightImagePath = payload.frontRightImagePath,
                    let frontLeftImagePath = payload.frontLeftImagePath,
                    let backRightImagePath = payload.backRightImagePath,
                    let backLeftImagePath = payload.backLeftImagePath
                else {
                    await MainActor.run {
                        alertTitle = "Missing Photos"
                        alertMessage = "Please wait for all images to finish uploading before submitting."
                        showAlert = true
                    }
                    return .doNothing
                }

                let body = [
                    "vehicle_vin": payload.vehicleVin,
                    "left_image_path": leftImagePath,
                    "right_image_path": rightImagePath,
                    "front_image_path": frontImagePath,
                    "back_image_path": backImagePath,
                    "front_right_image_path": frontRightImagePath,
                    "front_left_image_path": frontLeftImagePath,
                    "back_right_image_path": backRightImagePath,
                    "back_left_image_path": backLeftImagePath
                ]
                
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                
                let request = veygoCurlRequest(
                    url: "/api/v1/vehicle/generate-snapshot",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ],
                    body: jsonData
                )
                
                await MainActor.run {
                    isSubmitting = true
                }
                let (data, response) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    isSubmitting = false
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    if let decodedString = String(data: data, encoding: .utf8) {
                            print("Decoded String: \(decodedString)")
                        } else {
                            print("Decoding failed.")
                        }
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 201:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(VehicleSnapshot.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        alertTitle = "Success"
                        alertMessage = "Snapshot generated successfully. ID: \(decodedBody.id)"
                        clearScreen = true
                        showAlert = true
                    }
                    return .doNothing
                case 400:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) else {
                        let msg = ErrorResponse.E400
                        await MainActor.run {
                            alertTitle = msg.title
                            alertMessage = msg.message
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                    return .doNothing
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}
