//
//  LikeButtonView.swift
//  Roar
//
//  Created by Bourbon on 4/14/26.
//

import SwiftUI

struct LikeButtonView: View {
    let isLikedLocal: Bool
    let isLikedServer: Bool?
    let likeCount: Int?
    let onTap: () -> Void
    
    // likeCount = server likes + local likes. This is bad but prevents double-counting likes from current user
    private var displayCount: Int {
        return ((likeCount ?? 0) != 0
                ? ((isLikedServer ?? false)
                   ? -1 + (likeCount ?? 0)
                   : 0 + (likeCount ?? 0))
                : 0)
        + (isLikedLocal ? 1 : 0)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                
                Image(systemName: isLikedLocal ? "heart.fill" : "heart")
                    .foregroundColor(isLikedLocal ? .red : .gray)
                
                
                Text("\(displayCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            }
        }
        .buttonStyle(.plain)
    }
}
