//
//  UIImageViewExpandingAnim.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 02/05/24.
//

import UIKit

extension UIImageView {
    func expandToFullScreen(from startRect: CGRect, duration: TimeInterval, max limit: CGRect) {
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene else {
            return
        }
        
        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        let finalFrame = limit
        
        self.frame = startRect
        window.addSubview(self)
        
        UIView.animate(withDuration: duration) {
            self.frame = finalFrame
        }
    }
}
