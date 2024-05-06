//
//  UIViewExpandingAnim.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 02/05/24.
//

import UIKit

class CustomTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let duration: TimeInterval = 0.5
    var presenting = true
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let snapshot = presenting ? toView.snapshotView(afterScreenUpdates: true) : fromView.snapshotView(afterScreenUpdates: true),
              let fromVC = transitionContext.viewController(forKey: .from) as? ImageMessageExpandViewController,
              let toVC = transitionContext.viewController(forKey: .to) as? ChatController else {
            return
        }

        let initialFrame = presenting ? fromVC.startFrame ?? .zero : fromView.frame
        let finalFrame = presenting ? fromVC.endFrame ?? .zero : toVC.view.frame

        snapshot.frame = initialFrame
        containerView.addSubview(snapshot)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            snapshot.frame = finalFrame
        }, completion: { _ in
            if !self.presenting {
                fromView.removeFromSuperview()
            }
            transitionContext.completeTransition(true)
        })
    }
}
