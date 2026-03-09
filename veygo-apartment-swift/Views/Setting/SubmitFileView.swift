//
//  DriversLicenseView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 12/2/25.
//

import SwiftUI

struct SubmitFileView: View {
    @State private var isSubmitting: Bool = false
    
    @State private var isShowingCamera1 = false
    @State private var isShowingCamera2 = false
    @State private var isShowingCamera3 = false
    @State private var isShowingCamera4 = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var path: [SettingDestination]
    
    @EnvironmentObject var session: UserSession
    var body: some View {
        if let user = session.user {
            VStack (spacing: 36) {
                PrimaryButton(text: "Upload Driver's License") {
                    isShowingCamera1 = true
                }
                .fullScreenCover(isPresented: $isShowingCamera1) {
                    CameraImagePicker { image in
                        // Convert to Data and upload
                        if let data = image.jpegData(compressionQuality: 0.5) {
                            Task {
                                await ApiCallActor.shared.appendApi { token, userId in
                                    await submitFileAsync(
                                        token,
                                        userId,
                                        data,
                                        .DriversLicense,
                                        "drivers_license_camera.jpg"
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
                .disabled(isSubmitting)
                
                if user.requiresSecondaryDriverLic {
                    SecondaryButton(text: "Upload Secondary License") {
                        isShowingCamera2 = true
                    }
                    .fullScreenCover(isPresented: $isShowingCamera2) {
                        CameraImagePicker { image in
                            // Convert to Data and upload
                            if let data = image.jpegData(compressionQuality: 0.5) {
                                Task {
                                    await ApiCallActor.shared.appendApi { token, userId in
                                        await submitFileAsync(
                                            token,
                                            userId,
                                            data,
                                            .DriversLicenseSecondary,
                                            "drivers_license_secondary_camera.jpg"
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
                    .disabled(isSubmitting)
                }
                
                SecondaryButton(text: "Upload Lease or Proof of Address")
                {
                    isShowingCamera3 = true
                }
                .fullScreenCover(isPresented: $isShowingCamera3) {
                    CameraImagePicker { image in
                        // Convert to Data and upload
                        if let data = image.jpegData(compressionQuality: 0.5) {
                            Task {
                                await ApiCallActor.shared.appendApi { token, userId in
                                    await submitFileAsync(
                                        token,
                                        userId,
                                        data,
                                        .LeaseAgreement,
                                        "proof_of_address_camera.jpg"
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
                .disabled(isSubmitting)
                
                SecondaryButton(text: "Upload Proof of Insurance")
                {
                    isShowingCamera4 = true
                }
                .fullScreenCover(isPresented: $isShowingCamera4) {
                    CameraImagePicker { image in
                        // Convert to Data and upload
                        if let data = image.jpegData(compressionQuality: 0.5) {
                            Task {
                                await ApiCallActor.shared.appendApi { token, userId in
                                    await submitFileAsync(
                                        token,
                                        userId,
                                        data,
                                        .ProofOfInsurance,
                                        "proof_of_insurance_camera.jpg"
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
                .disabled(isSubmitting)
                
                Text("* Please make sure both your name and your address are clearly visible in the photos. ")
                    .font(.caption.italic())
                    .foregroundStyle(Color.footNote)
                
                Spacer()
                
            }
            .padding(20)
            .background(Color.mainBG.ignoresSafeArea(.all))
            .navigationTitle("Submit Documents")
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                }
            } message: {
                Text(alertMessage)
            }
        } else {
            EmptyView()
        }
    }
    
    enum FileType: String {
        case DriversLicense
        case DriversLicenseSecondary
        case LeaseAgreement
        case ProofOfInsurance
    }
    
    @ApiCallActor func submitFileAsync (_ token: String, _ userId: Int, _ file: Data, _ fileType: FileType, _ fileName: String) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                let request = veygoCurlRequest(
                    url: "/api/v1/user/upload-file",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)",
                        "Content-Type": "application/octet-stream",
                        "file-type": fileType.rawValue,
                        "file-name": fileName
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
                case 200:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        alertTitle = "Uploaded Successfully"
                        alertMessage = "Uploaded your document successfully."
                        showAlert = true
                        session.user = decodedBody
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
