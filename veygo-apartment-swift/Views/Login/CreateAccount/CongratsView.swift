//
//  CongratsView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI
import CoreMotion
public import Combine

/// Publishes device tilt (roll/pitch), normalized to roughly -1...1,
/// for driving a parallax effect.
@MainActor
final class MotionManager: ObservableObject {
    @Published var roll: Double = 0   // left/right tilt
    @Published var pitch: Double = 0  // forward/back tilt

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            // Clamp so extreme tilts don't fling emoji off-screen.
            self.roll = max(-1, min(1, motion.attitude.roll))
            self.pitch = max(-1, min(1, motion.attitude.pitch))
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

struct CongratsView: View {
    @Environment(Session.self) private var session
    @StateObject private var motion = MotionManager()

    let user: RegisteredRenter

    // Decorative emoji. Last field is the parallax depth: bigger = moves more.
    // (emoji, size, xFraction, yFraction, depth)
    private let decorations: [(String, CGFloat, CGFloat, CGFloat, CGFloat)] = [
        ("🍻", 62, 0.22, 0.16, 18),   // top-left
        ("🤩", 60, 0.78, 0.11, 26),   // top-right
        ("🎉", 52, 0.19, 0.53, 14),   // left, beside title
        ("🎈", 65, 0.72, 0.60, 34),   // right — balloon drifts most
        ("🥳", 52, 0.86, 0.46, 22),   // right
        ("🎊", 56, 0.29, 0.86, 16),   // bottom-left
        ("🎁", 58, 0.78, 0.80, 20)    // bottom-right
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.mainBG.ignoresSafeArea()

                // Edge decorations — base position fixed; only an offset
                // driven by tilt is applied, so size/layout never change.
                ForEach(Array(decorations.enumerated()), id: \.offset) { _, item in
                    Text(item.0)
                        .font(.system(size: item.1))
                        .position(
                            x: geo.size.width * item.2,
                            y: geo.size.height * item.3
                        )
                        .offset(
                            x: motion.roll * item.4,
                            y: motion.pitch * item.4
                        )
                        .animation(.easeOut(duration: 0.25), value: motion.roll)
                        .animation(.easeOut(duration: 0.25), value: motion.pitch)
                }

                // Title — no tilt offset, stays fixed.
                VStack(spacing: 6) {
                    Text("Congratulations,")
                        .font(.title)
                        .foregroundColor(Color.textBlackPrimary)
                    Text("Welcome To")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.textBlackPrimary)
                    Text("Veygo Family")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.textBlackPrimary)
                }
                .multilineTextAlignment(.center)
                .frame(width: geo.size.width)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.35)

                // Button — fixed, no tilt offset.
                ArrowButton {
                    session.login(token: user.token, userId: user.renter.id, renter: user.renter)
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.72)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

#Preview {
    let mockRenter = PublishRenter(
        id: 1,
        name: "John Appleseed",
        studentEmail: "john@veygo.rent",
        studentEmailExpiration: nil,
        phone: "765-000-0000",
        phoneIsVerified: true,
        dateOfBirth: "2000-01-01",
        profilePicture: nil,
        gender: nil,
        dateOfRegistration: Date(),
        driversLicenseNumber: nil,
        driversLicenseStateRegion: nil,
        driversLicenseImage: nil,
        driversLicenseImageSecondary: nil,
        driversLicenseExpiration: nil,
        insuranceIdImage: nil,
        insuranceLiabilityExpiration: nil,
        insuranceCollisionValid: false,
        leaseAgreementImage: nil,
        apartmentId: 1,
        leaseAgreementExpiration: nil,
        billingAddress: nil,
        signatureImage: nil,
        signatureDatetime: nil,
        planTier: .free,
        planRenewalDay: "1",
        planExpireMonthYear: "01/2030",
        isPlanAnnual: false,
        employeeTier: .user,
        subscriptionPaymentMethodId: nil,
        requiresSecondaryDriverLic: false,
        planTotalAvailability: FlexDecimal(0)
    )

    return CongratsView(user: RegisteredRenter(token: "preview-token", renter: mockRenter))
        .environment(Session())
}
