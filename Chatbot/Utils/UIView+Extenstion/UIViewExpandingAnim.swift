//
//  UIViewExpandingAnim.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 02/05/24.
//

import UIKit

extension UIView {
    func expandToFullScreen(from startRect: CGRect, duration: TimeInterval) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        guard let window = windowScenes?.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        let finalFrame = window.frame
        
        self.frame = startRect
        window.addSubview(self)
        
        UIView.animate(withDuration: duration) {
            self.frame = finalFrame
        }
    }
}
