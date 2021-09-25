//
//  SyncStatusBarView.swift
//  SyncStatusBarView
//
//  Created by Lawrence Bensaid on 19/09/2021.
//

import SwiftUI

struct SyncStatusBarView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(Color("Divider2"))
                .frame(maxWidth: .infinity, minHeight: 0.5, maxHeight: 0.5)
            Spacer(minLength: 0)
            content()
                .frame(maxWidth: .infinity)
                .offset(y: -1)
            Spacer(minLength: 0)
        }
        .background(BlurView())
        .frame(height: 28)
    }
    
}

struct SyncStatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        SyncStatusBarView {
            HStack(spacing: 16) {
                Text("3 out of 5 files available for synchronization")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
            }
        }
    }
}
