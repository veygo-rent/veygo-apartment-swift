//
//  SubmitFileView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/2/26.
//

import SwiftUI

struct SubmitFileView: View {
    @Environment(Session.self) private var session

    @State private var isSubmitting: Bool = false
    @State private var activeUpload: FileType? = nil   // drives the single camera cover

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    /// The document kinds the server accepts. Raw values are the exact
    /// `file-type` header strings the backend expects.
    enum FileType: String, Identifiable {
        case driversLicense          = "DriversLicense"
        case driversLicenseSecondary = "DriversLicenseSecondary"
        case leaseAgreement          = "LeaseAgreement"
        case proofOfInsurance        = "ProofOfInsurance"

        var id: String { rawValue }

        var fileName: String {
            switch self {
            case .driversLicense:          return "drivers_license_camera.jpg"
            case .driversLicenseSecondary: return "drivers_license_secondary_camera.jpg"
            case .leaseAgreement:          return "proof_of_address_camera.jpg"
            case .proofOfInsurance:        return "proof_of_insurance_camera.jpg"
            }
        }
    }

    var body: some View {
        Group {
            if let user = session.renter {
                content(user: user)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func content(user: PublishRenter) -> some View {
        VStack(spacing: 36) {
            PrimaryButton(text: "Upload Driver's License") {
                activeUpload = .driversLicense
            }
            .disabled(isSubmitting)

            if user.requiresSecondaryDriverLic {
                SecondaryButton(text: "Upload Secondary License") {
                    activeUpload = .driversLicenseSecondary
                }
                .disabled(isSubmitting)
            }

            SecondaryButton(text: "Upload Lease or Proof of Address") {
                activeUpload = .leaseAgreement
            }
            .disabled(isSubmitting)

            SecondaryButton(text: "Upload Proof of Insurance") {
                activeUpload = .proofOfInsurance
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
        // One camera cover for all four buttons; `item` tells us which document.
        .fullScreenCover(item: $activeUpload) { fileType in
            CameraImagePicker { image in
                handleCapture(image, for: fileType)
            }
            .ignoresSafeArea(edges: .all)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Capture → upload

    private func handleCapture(_ image: UIImage, for fileType: FileType) {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            present(title: "Camera Error", message: "Failed to read captured image.")
            return
        }
        Task { await upload(data, as: fileType) }
    }

    private func upload(_ data: Data, as fileType: FileType) async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let renter = try await uploadRequest(data, as: fileType)
            session.setRenter(renter)   // server returns the updated profile
            present(title: "Uploaded Successfully", message: "Uploaded your document successfully.")
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func uploadRequest(_ data: Data, as fileType: FileType) async throws -> PublishRenter {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/user/upload-file",
            method: .post,
            headers: [
                "auth": "\(token)$\(userId)",
                "Content-Type": "application/octet-stream",
                "file-type": fileType.rawValue,
                "file-name": fileType.fileName
            ],
            body: data
        )
        do {
            let (respData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: respData)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: respData)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: respData)) ?? .E_DEFAULT
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
