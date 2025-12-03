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
            PrimaryButton(text: "Select File") {
                isImporting = true
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.image, .pdf], // Specify allowed file types (e.g., .text, .data, .jpeg)
                allowsMultipleSelection: false // Set to true for multiple file selection
            ) { result in
                switch result {
                case .success(let urls):
                    // Handle the selected file URLs here
                    // For single selection, urls.first will contain the URL
                    if let fileURL = urls.first {
                        print("Selected file: \(fileURL.lastPathComponent)")
                        // Further processing of the fileURL
                    }
                case .failure(let error):
                    // Handle any errors during file selection
                    print("File selection error: \(error.localizedDescription)")
                }
            }
            
            Spacer()

        }
        .padding(.horizontal, 20)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle("Submit Drivers License")
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
