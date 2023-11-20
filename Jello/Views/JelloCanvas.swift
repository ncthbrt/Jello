import SwiftUI


import Foundation
import UIKit


struct PanZoomGesture {
    let startDistance: CGFloat
    let currentDistance: CGFloat
    let startCentroid: CGPoint
    let currentCentroid: CGPoint
}

class PanZoomGestureRecognizer: UIGestureRecognizer {
    
    private var startCentroid: CGPoint = .zero
    private var startDistance: CGFloat = .zero
    
    var onGesture: (PanZoomGesture) -> ()
    var onGestureEnd: () -> ()

    init(target: Any?, onGesture: @escaping (PanZoomGesture) -> (), onGestureEnd: @escaping () -> ()) {
        self.onGesture = onGesture
        self.onGestureEnd = onGestureEnd
        super.init(target: target, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            if (self.numberOfTouches == 2) { // we have a two finger interaction starting
                self.state = .began
                self.startCentroid = location(in: view)
                self.startDistance = (location(ofTouch: 0, in: view) - location(ofTouch: 1, in: view)).magnitude()
                onGesture(PanZoomGesture(startDistance: startDistance, currentDistance: startDistance, startCentroid: startCentroid, currentCentroid: startCentroid))
            }
        } else {        // check to see if there are more touches
            if (self.numberOfTouches > 2){ // too many fingers
                self.state = .failed
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
        onGestureEnd()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if (self.state != .possible) {
            self.state = .changed
            if (self.numberOfTouches == 2) {
                let currentCentroid = location(in: view)
                let currentDistance = (location(ofTouch: 0, in: view) - location(ofTouch: 1, in: view)).magnitude()
                onGesture(PanZoomGesture(startDistance: startDistance, currentDistance: currentDistance, startCentroid: startCentroid, currentCentroid: currentCentroid))
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if numberOfTouches == 2 {
            state = .ended
            onGestureEnd()
        }
        else {
            state = .failed
        }
    }
    

}


struct JelloCanvasRepresentable<Content: View> : UIViewRepresentable {
    let onPanZoomGesture: (PanZoomGesture) -> ()
    let onPanZoomGestureEnd: () -> ()
    
    private var content: Content
    

    init(onPanZoomGesture: @escaping (PanZoomGesture) -> (), onPanZoomGestureEnd: @escaping () -> (), @ViewBuilder content: () -> Content) {
        self.onPanZoomGesture = onPanZoomGesture
        self.onPanZoomGestureEnd = onPanZoomGestureEnd
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addGestureRecognizer(context.coordinator.gestureRecognizer)
        view.addSubview(context.coordinator.hostingController.view)
        view.isMultipleTouchEnabled = true

        let hostingController = context.coordinator.hostingController
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.hostingController.rootView = self.content
        context.coordinator.gestureRecognizer.onGesture = onPanZoomGesture
        context.coordinator.gestureRecognizer.onGestureEnd = onPanZoomGestureEnd
        assert(context.coordinator.hostingController.view.superview == uiView)
     }
    
    func makeCoordinator() -> Coordinator {
        let hostingController = UIHostingController(rootView: self.content)
        let recognizer = PanZoomGestureRecognizer(target: nil, onGesture: onPanZoomGesture, onGestureEnd: onPanZoomGestureEnd)
        let coordinator = Coordinator(hostingController: hostingController, gestureRecognizer: recognizer)
        recognizer.delegate = coordinator
        return coordinator
    }
       
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var hostingController: UIHostingController<Content>
        var gestureRecognizer: PanZoomGestureRecognizer
        
        init(hostingController: UIHostingController<Content>, gestureRecognizer: PanZoomGestureRecognizer) {
            self.hostingController = hostingController
            self.gestureRecognizer = gestureRecognizer
        }
                 
    }
    
}
