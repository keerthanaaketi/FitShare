//
//  WeightFooterView.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 21/05/24.
//

import Foundation
import SwiftUI

struct WeightFooterView: View {
    @Binding var isPresentingWeightView: Bool
    let refreshAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                refreshAction()
            }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
            Spacer()
            Button(action: {
                // Share functionality
            }) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
                    .font(.system(size: 35))
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
            Spacer()
            Button(action: {
                isPresentingWeightView = false
            }) {
                Image(systemName: "house.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
        }
        .padding()
    }
}
