//
//  AvatarView.swift
//  Roar
//
//  Created by Bourbon on 4/15/26.
//

import SwiftUI

struct AvatarView: View {
    let url: URL?
    let width: Int
    let height: Int
    
    init(url: URL?, width: Int = 40, height: Int = 40) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: CGFloat(width), height: CGFloat(height))
        .clipShape(Circle())
        .onAppear {
            if let url {
                loader.load(from: url)
            }
        }
    }
}
