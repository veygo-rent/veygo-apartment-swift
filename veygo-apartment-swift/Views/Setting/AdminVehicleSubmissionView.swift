//
//  AdminVehicleSubmissionView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 12/22/25.
//

import SwiftUI
import CodeScanner

struct AdminVehicleSubmissionView: View {
    @State private var vinInput: String = ""
    @State private var isScanningVin: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
    @State private var isSubmitting: Bool = false
    @State private var isShowingCamera = false
    
    @State private var leftImage: (String, UIImage)? = nil
    @State private var rightImage: (String, UIImage)? = nil
    @State private var frontImage: (String, UIImage)? = nil
    @State private var backImage: (String, UIImage)? = nil
    @State private var rearRight: (String, UIImage)? = nil
    @State private var rearLeft: (String, UIImage)? = nil
    @State private var frontRight: (String, UIImage)? = nil
    @State private var frontLeft: (String, UIImage)? = nil
    
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
                    .disabled(isSubmitting || allImagesCaptured)
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
                    .disabled(isSubmitting || !allImagesCaptured)

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
                if let data = image.jpegData(compressionQuality: 0.5) {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await submitFileAsync(
                                token,
                                userId,
                                data,
                                "vehicle_inspection_camera.jpg",
                                image
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
    private func imageTile(label: String, binding: Binding<(String, UIImage)?>) -> some View {
        let tileCorner: CGFloat = 16

        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.textBlackPrimary)

            ZStack(alignment: .topTrailing) {
                if let img = binding.wrappedValue?.1 {
                    ZStack {
                        GeometryReader { geo in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
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
    
    @ApiCallActor func submitFileAsync (_ token: String, _ userId: Int, _ file: Data, _ fileName: String, _ image: UIImage) async -> ApiTaskResponse {
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
                    body: file
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FilePath.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        if leftImage == nil {
                            leftImage = (decodedBody.filePath, image)
                        } else if frontLeft == nil {
                            frontLeft = (decodedBody.filePath, image)
                        } else if frontImage == nil {
                            frontImage = (decodedBody.filePath, image)
                        } else if frontRight == nil {
                            frontRight = (decodedBody.filePath, image)
                        } else if rightImage == nil {
                            rightImage = (decodedBody.filePath, image)
                        } else if rearRight == nil {
                            rearRight = (decodedBody.filePath, image)
                        } else if backImage == nil {
                            backImage = (decodedBody.filePath, image)
                        } else if rearLeft == nil {
                            rearLeft = (decodedBody.filePath, image)
                        }
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
    
    @ApiCallActor func generateSnapshotAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                let body = [
                    "vehicle_vin": await vinInput,
                    "left_image_path": await leftImage!.0,
                    "right_image_path": await rightImage!.0,
                    "front_image_path": await frontImage!.0,
                    "back_image_path": await backImage!.0,
                    "front_right_image_path": await frontRight!.0,
                    "front_left_image_path": await frontLeft!.0,
                    "back_right_image_path": await rearRight!.0,
                    "back_left_image_path": await rearLeft!.0
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
