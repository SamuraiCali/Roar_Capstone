//
//  ImageLoader.swift
//  Roar
//
//  Created by Bourbon on 4/15/26.
//

import Foundation
import UIKit
internal import Combine

final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private static let cache = NSCache<NSURL, UIImage>()
    
//    init() {
//        Self.cache.removeAllObjects()
//    }
    
    func load(from url: URL) {
        if let cached = Self.cache.object(forKey: url as NSURL) {
            self.image = cached
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await MainActor.run {
                        Self.cache.setObject(img, forKey: url as NSURL)
                        self.image = img
                    }
                }
            } catch {
                print("Image load failed:", error)
            }
        }
    }
}
