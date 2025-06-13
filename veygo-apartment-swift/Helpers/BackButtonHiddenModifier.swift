//
//  BackButtonHiddenModifier.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 6/13/25.
//
// Conditional for iOS 26

import SwiftUI

struct BackButtonHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content
                .navigationBarBackButtonHidden(true)
        }
    }
}
