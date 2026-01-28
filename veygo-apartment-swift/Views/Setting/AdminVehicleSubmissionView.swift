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
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                HStack (spacing: 18) {
                    TextInputField(placeholder: "VIN Number", text: $vinInput)
                        .disabled(true)
                    SecondaryButton(text: "Scan") {
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
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color("MainBG").ignoresSafeArea(.all))
    }
}
