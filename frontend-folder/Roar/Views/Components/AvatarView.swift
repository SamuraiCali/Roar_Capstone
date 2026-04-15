//
//  AvatarView.swift
//  Roar
//
//  Created by Bourbon on 4/15/26.
//

import SwiftUI

struct AvatarView: View {
    let url: URL?
    
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
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .onAppear {
            if let url {
                loader.load(from: url)
            }
        }
    }
}
