//
//  DriversLicenseView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 12/2/25.
//

import SwiftUI

struct DriversLicenseView: View {
    @State private var isImporting: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var path: [SettingDestination]
    
    @EnvironmentObject var session: UserSession
    var body: some View {
        VStack {
            PrimaryButton(text: "Select Driver's License") {
                isImporting = true
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.image, .pdf], // Specify allowed file types (e.g., .text, .data, .jpeg)
                allowsMultipleSelection: false // Set to true for multiple file selection
            ) { result in
                switch result {
                case .success(let urls):
                    if let file = urls.first,
                       file.startAccessingSecurityScopedResource() {
                        let data: Data = try! Data(contentsOf: file)
                    } else {
                        alertMessage = "File selection error"
                        alertTitle = "File Error"
                        showAlert.toggle()
                    }
                case .failure(let error):
                    alertMessage = "File selection error: \(error.localizedDescription)"
                    alertTitle = "File Error"
                    showAlert.toggle()
                }
            }
            
            Spacer()

        }
        .padding(.horizontal, 20)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle("Submit File")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
}
