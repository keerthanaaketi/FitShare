//
//  SlabView.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 17/05/24.
//

import Foundation
import SwiftUI

struct SlabView: View {
    var title: String
    var total: String
    var goal: String
    var remaining: String

    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray)
                .frame(width: 390, height: 90)
                .overlay(VStack {
                    HStack{
                        Text("\t")
                        Text(title)
                            .font(.title2).bold()
                        Spacer()
                        Text(total)
                            .font(.title3)
                        Spacer()
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("Goal:"+goal)
                            .font(.headline)
                        Spacer()
                        if let remainingInt = Int(remaining), remainingInt > 0 {
                            Text("Left: \(remaining)")
                                .font(.headline)
                        } else {
                            Text("Goal Reached")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                })
        }
    }
}
