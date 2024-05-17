//
//  AdaptiveText.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 18/05/24.
//

import Foundation
import SwiftUI

struct AdaptiveText: View {
    var text: String
    var font: Font
    var color: Color
    
    @State private var fontSize: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.trailing, 8)
                .background(GeometryReader { textGeometry in
                    Color.clear.onAppear {
                        let textWidth = textGeometry.size.width
                        let containerWidth = geometry.size.width
                        
                        if textWidth > containerWidth {
                            let scaleFactor = containerWidth / textWidth
                            fontSize = fontSize * scaleFactor
                        }
                    }
                })
        }
        .frame(height: 20)
    }
}
