//
//  UIViewExpandingAnim.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 02/05/24.
//

import UIKit

extension CGAffineTransform {
    init(from source: CGRect, to destination: CGRect) {
        self = CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }
}
