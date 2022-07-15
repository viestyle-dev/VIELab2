//
//  GraphScene.swift
//  GraphViewStudy
//
//  Created by mio kato on 2022/03/15.
//

import SpriteKit

class GraphScene: SKScene {
    
    private var values = [Float]()
    private let maxValues = Constants.samplingRate * Constants.waveDuration

    var viewHeight: Float!
    let maxHeight: Float = 5000
    
    override func didMove(to view: SKView) {
        view.preferredFramesPerSecond = 60
        scene?.backgroundColor = .black
        
        viewHeight = Float(view.frame.height) * 0.5
    }
    
    func setValues(values: [Float]) {
        self.values = values
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard values.count == maxValues else {
            return
        }
        
        var points = [CGPoint]()
        for (i, value) in self.values.enumerated() {
            let ratio = value / maxHeight            
            let height = viewHeight * ratio
            let point = CGPoint(x: CGFloat(i), y: CGFloat(height))
            points.append(point)
        }
        draw(points: points)
    }
    
    func draw(points: [CGPoint]) {
        removeAllChildren()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        
        for point in points {
            path.addCurve(to: point, controlPoint1: point, controlPoint2: point)
        }

        let shapeNode = SKShapeNode(path: path.cgPath)
        shapeNode.strokeColor = UIColor.white
        addChild(shapeNode)

    }
}
